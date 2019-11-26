//
//  NTDirMonitorMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTDirMonitorMgr.h"
#import "NTDirMonitorObserver.h"
#import "NTDirMonitorItem.h"

@interface NTDirMonitorMgr ()
@property (nonatomic, retain) NSMutableDictionary *sourceObservers;
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@end

@implementation NTDirMonitorMgr

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize sourceObservers, dispatchQueue;

- (id)init;
{
	self = [super init];
	
	self.sourceObservers = [NSMutableDictionary dictionary];
	self.dispatchQueue = dispatch_queue_create("com.cocoatech.dirMonitorMgr", NULL);
	
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
	if (self.dispatchQueue)
	{
		dispatch_release(self.dispatchQueue);
		self.dispatchQueue = nil;
	}
	
    self.sourceObservers = nil;
    [super dealloc];
}

- (void)addObserver:(NTMessageProxy*)theObserverProxy forItem:(NTDirMonitorItem*)theItem;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			NTDirMonitorObserver* theSourceObserver = [self.sourceObservers objectForKey:theItem.identifier];
			if (!theSourceObserver)
			{
				theSourceObserver = [NTDirMonitorObserver observer:theItem];
				
				[self.sourceObservers setObject:theSourceObserver forKey:theItem.identifier];
			}
			
			[theSourceObserver addObserver:theObserverProxy];			
		}
		@catch (NSException * e) {
			NSLog(@"addObserver exception: %@", e);
		}
		@finally {
		}
	});
}

- (void)removeObserver:(NTMessageProxy*)theObserverProxy forItem:(NTDirMonitorItem*)theItem;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			NTDirMonitorObserver* theSourceObserver = [self.sourceObservers objectForKey:theItem.identifier];
			
			if (theSourceObserver)
			{
				[theSourceObserver removeObserver:theObserverProxy];
				
				if ([theSourceObserver empty])
					[self.sourceObservers removeObjectForKey:theItem.identifier];
			}
		}
		@catch (NSException * e) {
			NSLog(@"removeObserver exception: %@", e);
		}
		@finally {
		}
	});
}

@end

@implementation NTDirMonitorMgr (NTDirMonitorObserverAccess)

- (void)dirMonitorObserverWasModified:(NSString*)itemIdentifer;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			NTDirMonitorObserver* theSourceObserver = [self.sourceObservers objectForKey:itemIdentifer];
			if (theSourceObserver)
			{
				NSArray* theObserverProxys = [theSourceObserver observers];
				
				// was sync so it happens under the umbrella of the sync queue
				// but, I think it should be thread safe since the Observers array is safe
				dispatch_async(dispatch_get_main_queue(), ^{
					@try {
						for (NTMessageProxy* theObserverProxy in theObserverProxys)
							[theObserverProxy notify:nil];
					}
					@catch (NSException * e) {
						NSLog(@"dirMonitorObserverWasModified exception: %@", e);
					}
					@finally {
					}
				});
			}
		}
		@catch (NSException * e) {
			NSLog(@"dirMonitorObserverWasModified2 exception: %@", e);
		}
		@finally {
		}
	});
}

@end
