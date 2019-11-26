//
//  NTDispatchSourceMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTDispatchSourceMgr.h"
#import "NTDispatchSourceObserver.h"
#import "NTDispatchSourceItem.h"
#import "NTFileEnvironment.h"

@interface NTDispatchSourceMgr ()
@property (nonatomic, retain) NSMutableDictionary *sourceObservers;
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@end

@implementation NTDispatchSourceMgr

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize sourceObservers, dispatchQueue;

- (id)init;
{
	self = [super init];
	
	self.sourceObservers = [NSMutableDictionary dictionary];
	self.dispatchQueue = dispatch_queue_create("com.cocoatech.dispatchSourceMgr", NULL);
	
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

- (void)addObserver:(NTMessageProxy*)theObserverProxy forItem:(NTDispatchSourceItem*)theItem;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			NTDispatchSourceObserver* theSourceObserver = [self.sourceObservers objectForKey:theItem.identifier];
			if (!theSourceObserver)
			{
				theSourceObserver = [NTDispatchSourceObserver observer:theItem];
				
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

- (void)removeObserver:(NTMessageProxy*)theObserverProxy forItem:(NTDispatchSourceItem*)theItem;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			NTDispatchSourceObserver* theSourceObserver = [self.sourceObservers objectForKey:theItem.identifier];
			
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

@implementation NTDispatchSourceMgr (NTDispatchSourceObserverAccess)

- (void)sourceObserverWasModified:(NSString*)itemIdentifier;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			NTDispatchSourceObserver* theSourceObserver = [self.sourceObservers objectForKey:itemIdentifier];
			if (theSourceObserver)
			{
				NSArray* theObserverProxys = [theSourceObserver observers];
				
				if (FENV(logKQueueEvents))
					[[NTFileEnvironment sharedInstance] notify_KQueueEvent:[theSourceObserver description]];
				
				// was sync so it happens under the umbrella of the sync queue
				// but, I think it should be thread safe since the Observers array is safe
				dispatch_async(dispatch_get_main_queue(), ^{
					@try {
						for (NTMessageProxy* theObserverProxy in theObserverProxys)
							[theObserverProxy notify:nil];
					}
					@catch (NSException * e) {
						NSLog(@"sourceObserverWasModified exception: %@", e);
					}
					@finally {
					}
				});
			}
		}
		@catch (NSException * e) {
			NSLog(@"sourceObserverWasModified2 exception: %@", e);
		}
		@finally {
		}
	});
}

@end
