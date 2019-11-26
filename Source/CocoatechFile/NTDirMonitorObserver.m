//
//  NTDirMonitorObserver.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTDirMonitorObserver.h"
#import "NTDirMonitorMgr.h"
#import "NTDispatchFSESource.h"
#import "NTDirMonitorItem.h"
#import "NTFSEventClient.h"

@interface NTDirMonitorObserver ()
@property (nonatomic, retain) NSMutableArray *mutableObservers;
@property (nonatomic, retain) NTFSEventClient *eventClient;
@property (nonatomic, retain) NTMessageProxy* proxy;
@property (nonatomic, retain) NTDirMonitorItem *item;
@end

@interface NTDirMonitorObserver (Protocols) <NTMessageProxyProtocol>
@end

@implementation NTDirMonitorObserver

@synthesize mutableObservers;
@synthesize eventClient;
@synthesize proxy;
@synthesize item;

+ (NTDirMonitorObserver*)observer:(NTDirMonitorItem*)theItem;
{
	NTDirMonitorObserver* result = [[self alloc] init];
	
	result.item = theItem;
	result.mutableObservers = [NSMutableArray array];
	result.proxy = [NTMessageProxy proxy:result];

	result.eventClient = [NTFSEventClient client:result.proxy folder:[theItem parentDesc]];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[self.proxy invalidate];
	self.proxy = nil;

	self.eventClient = nil;
	self.item = nil;

    self.mutableObservers = nil;
	
    [super dealloc];
}

- (void)addObserver:(NTMessageProxy*)theObserver;
{
	[self.mutableObservers addObject:theObserver];
}

- (void)removeObserver:(NTMessageProxy*)theObserver;
{
	[self.mutableObservers removeObjectIdenticalTo:theObserver];
}

- (BOOL)empty;
{
	return ([self.mutableObservers count] == 0);
}

- (NSArray*)observers;
{
	return [NSArray arrayWithArray:self.mutableObservers];
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@ : %@", NSStringFromClass([self class]), [self.item.desc path]];
}

@end

@implementation NTDirMonitorObserver (Protocols)

// NTMessageProxyProtocol
- (void)messageProxy:(NTMessageProxy*)theProxy message:(id)inMessage;
{
	NTFileDesc* theDesc = self.item.desc;
	
	// hasBeenModified touches disk, put it in a gcd queue
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		@try {		
			if ([theDesc hasBeenModified:self.item.networkVolume])
			{				
				// tell the delegateProxy on main thread
				dispatch_async(dispatch_get_main_queue(), ^{
					@try {
						[[NTDirMonitorMgr sharedInstance] dirMonitorObserverWasModified:[self.item identifier]];
					}
					@catch (NSException * e) {
						NSLog(@"-[%@ %@] (1) exception: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), e);
					}
					@finally {
					}
				});
			}			
		}
		@catch (NSException * e) {
			NSLog(@"-[%@ %@] (2) exception: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), e);
		}
		@finally {
		}
	});	
}

@end
