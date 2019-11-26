//
//  NTVolumeModifiedWatcher.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/7/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "NTVolumeModifiedWatcher.h"
#import "NTFSEventClient.h"
#import "NTDefaultDirectory.h"
#import "NTVolume.h"
#import "NTVolumeMgrState.h"
#import "NTVolumeSpec.h"
#import "NTVolumeMgr.h"

@interface NTVolumeModifiedWatcher (Protocols) <NTMessageProxyProtocol>
@end

@interface NTVolumeModifiedWatcher ()
@property (nonatomic, retain) NTFSEventClient *computerWatcher;
@property (nonatomic, retain) NSArray *volumeWatchers;
@property (nonatomic, retain) NSDictionary *volumeFreespaceCache;
@property (nonatomic, assign) BOOL rescanningAsync;
@property (nonatomic, assign) BOOL rebuildingAsync;
@property (nonatomic, retain) NTMessageProxy* proxy;
@end

@interface NTVolumeModifiedWatcher (Private) 
- (void)rebuildVolumeWatchers;
@end

@interface NTVolumeModifiedWatcher (ScanThread)
- (void)startAsyncScan:(NSDictionary*)thePreviousCache;
- (void)scanDoneOnMainThread:(NSArray*)theChangedVolumeSpecs freespaceCache:(NSDictionary*)theFreespaceCache;
@end

@interface NTVolumeModifiedWatcher (RebuildThread)
- (void)startAsyncRebuild;
- (void)rebuildDoneOnMainThread:(NSArray*)theVolumeWatchers;
@end

@implementation NTVolumeModifiedWatcher

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize computerWatcher;
@synthesize volumeWatchers;
@synthesize volumeFreespaceCache;
@synthesize rescanningAsync;
@synthesize rebuildingAsync;
@synthesize proxy;

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
	[self.proxy invalidate];
	self.proxy = nil;

    self.computerWatcher = nil;
	
    self.volumeFreespaceCache = nil;
	self.volumeWatchers = nil;

    [super dealloc];
}

- (id)init;
{
	self = [super init];
	
	self.proxy = [NTMessageProxy proxy:self];

	self.computerWatcher = [NTFSEventClient client:self.proxy folder:[[NTDefaultDirectory sharedInstance] computer]];

	// call once to prime it up
	[self startAsyncScan:nil];

	[self rebuildVolumeWatchers];
	
	return self;
}

@end

@implementation NTVolumeModifiedWatcher (Private) 

- (void)rebuildVolumeWatchers;
{
	if (!self.rebuildingAsync)
	{
		self.rebuildingAsync = YES;
		[self performDelayedSelector:@selector(rebuildVolumeWatchersAfterDelay) withObject:nil delay:5];
	}
}

- (void)rebuildVolumeWatchersAfterDelay;
{	
	[self startAsyncRebuild];
}

- (void)rescanVolumes;
{
	if (!self.rescanningAsync)
	{
		self.rescanningAsync = YES;
		[self performDelayedSelector:@selector(rescanVolumesAfterDelay) withObject:nil delay:10];
	}
}

- (void)rescanVolumesAfterDelay;
{		
	[self startAsyncScan:[NSDictionary dictionaryWithDictionary:self.volumeFreespaceCache]];
}

@end

@implementation NTVolumeModifiedWatcher (Protocols) 

// NTMessageProxyProtocol
- (void)messageProxy:(NTMessageProxy*)theProxy message:(id)inMessage;
{
	NSNumber* theClientID = [inMessage objectForKey:kFSEventClient_uniqueIDKey];
	
	// make sure we are watching all current volumes
	if ([theClientID isEqual:[self.computerWatcher uniqueID]])
	{
		// volume added or removed
		[self rebuildVolumeWatchers];
	}
	else // one of the volumeWatchers
	{
		// volume was modified, send out notification
		[self rescanVolumes];
	}
}

@end

@implementation NTVolumeModifiedWatcher (ScanThread)

- (void)startAsyncScan:(NSDictionary*)thePreviousCache;
{	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		@try {			
			NSMutableDictionary* freeSpaceDict  = [NSMutableDictionary dictionary];
			NSArray* theVolumes = [[NTVolumeMgr sharedInstance] freshVolumeSpecs];
			NSMutableArray *theChangedVolumeSpecs = [NSMutableArray array];
			
			for (NTVolumeSpec* volumeSpec in theVolumes)
			{
				NSNumber* newFreespace = [NSNumber numberWithUnsignedLongLong:[volumeSpec freeBytes]];
				[freeSpaceDict setObject:newFreespace forKey:[[volumeSpec mountPoint] dictionaryKey]];
				
				// only compare to what's in previous Cache
				if (thePreviousCache)
				{
					// does this volume exist in our cache? If not, we are changed
					NSNumber* oldFreespace = [thePreviousCache objectForKey:[[volumeSpec mountPoint] dictionaryKey]];
					if (oldFreespace)
					{
						if (abs([newFreespace unsignedLongLongValue] - [oldFreespace unsignedLongLongValue]) > (1024*512)) // must be greater than .5MB
							[theChangedVolumeSpecs addObject:volumeSpec];
					}
				}
			}
			
			NSDictionary* freespaceCache = [NSDictionary dictionaryWithDictionary:freeSpaceDict];
			NSArray* changedVolumeSpecs = [NSArray arrayWithArray:theChangedVolumeSpecs];
						
			dispatch_async(dispatch_get_main_queue(), ^{
				@try {
					[self scanDoneOnMainThread:changedVolumeSpecs freespaceCache:freespaceCache];
				}
				@catch (NSException * e) {
					NSLog(@"%@ exception (mainthread): %@", NSStringFromSelector(_cmd), e);
				}
				@finally {
				}
			});
		}
		@catch (NSException * e) {
			NSLog(@"%@ exception: %@", NSStringFromSelector(_cmd), e);
		}
		@finally {
		}
	});
}

- (void)scanDoneOnMainThread:(NSArray*)theChangedVolumeSpecs freespaceCache:(NSDictionary*)theFreespaceCache;
{
	// NSLog(@"%@ : changed:%@", NSStringFromSelector(_cmd), theChangedVolumeSpecs);

	self.rescanningAsync = NO;
	
	// first time run just to build the cache, so don't do anything if nil first time
	if (self.volumeFreespaceCache)
	{
		if ([theChangedVolumeSpecs count])
		{
			[NTFSEventClient manuallyRefreshDirectory:[[NTDefaultDirectory sharedInstance] computer]];
			
			NSMutableArray* volumeRefNums = [NSMutableArray array];
			for (NTVolumeSpec* spec in theChangedVolumeSpecs)
				[volumeRefNums addObject:[NSNumber numberWithInt:[spec volumeRefNum]]];
			
			// send notification to refresh freespace display in 
			[[NSNotificationCenter defaultCenter] postNotificationName:kNTVolumeFreespaceModifiedNotification
																object:nil 
															  userInfo:[NSDictionary dictionaryWithObject:volumeRefNums forKey:@"volumeRefNums"]];
		}
	}
	
	// save cache for next call
	self.volumeFreespaceCache = theFreespaceCache;
}

@end

@implementation NTVolumeModifiedWatcher (RebuildThread)

- (void)startAsyncRebuild;
{	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		@try {
			NSMutableArray* watchers = [NSMutableArray array];
			NSArray* volumes = [[[NTDefaultDirectory sharedInstance] computer] directoryContents:YES resolveIfAlias:NO];
			
			for (NTFileDesc* volume in volumes)
			{
				NTFSEventClient* theWatcher = [NTFSEventClient client:self.proxy folder:volume includeSubfolders:YES];
				
				if (theWatcher)
					[watchers addObject:theWatcher];
			}
			
			NSArray* theVolumeWatchers = [NSArray arrayWithArray:watchers];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				@try {
					[self rebuildDoneOnMainThread:theVolumeWatchers];
				}
				@catch (NSException * e) {
					NSLog(@"%@ exception (mainthread): %@", NSStringFromSelector(_cmd), e);
				}
				@finally {
				}
			});
		}
		@catch (NSException * e) {
			NSLog(@"%@ exception: %@", NSStringFromSelector(_cmd), e);
		}
		@finally {
		}
	});
}

- (void)rebuildDoneOnMainThread:(NSArray*)theVolumeWatchers;
{
	// NSLog(@"%@ : watchers:%@", NSStringFromSelector(_cmd), theVolumeWatchers);

	self.rebuildingAsync = NO;
		
	self.volumeWatchers = theVolumeWatchers;
}

@end

