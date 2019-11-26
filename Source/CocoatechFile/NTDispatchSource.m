//
//  NTDispatchSource.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTDispatchSource.h"
#include <unistd.h>

@interface NTDispatchSource ()
@property (nonatomic, assign) dispatch_source_t dispatchSource;
@property (nonatomic, retain) NTFileDesc* descriptionDesc;
@end

@interface NTDispatchSource(Private)
+ (void)closeFD:(int)theFD;
+ (void)closeFDAsync:(int)theFD;
+ (id)workerClassMethod:(NTFileDesc*)inDesc proxy:(NTMessageProxy*)inProxy;
@end

void closeFDAsync(int theFD, NTFileDesc* theDesc);

@implementation NTDispatchSource

@synthesize dispatchSource, descriptionDesc;

+ (NTDispatchSource*)source:(NTFileDesc*)theDesc delegateProxy:(NTMessageProxy*)theProxy;
{
	NTDispatchSource* result = [[self alloc] init];
	
	result.descriptionDesc = theDesc;  // this is just used for description, not needed otherwise

	if (theDesc && theProxy)
		[result dispatch:0 thread:@selector(worker:) main:@selector(worker_result:) param:[NSDictionary dictionaryWithObjectsAndKeys:theDesc, @"desc", theProxy, @"proxy", nil]];
	
	return [result autorelease];
}

- (void)dealloc
{		
	if (self.dispatchSource)
	{
		dispatch_source_cancel(self.dispatchSource);
		dispatch_release(self.dispatchSource);
		
		self.dispatchSource = nil;
	}
	
	self.descriptionDesc = nil;
	
    [super dealloc];
}

@end

@implementation NTDispatchSource(Private)

+ (void)closeFDAsync:(int)theFD;
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		@try {
			[self closeFD:theFD];
		}
		@catch (NSException * e) {
			NSLog(@"closeFDAsync exception: %@", e);
		}
		@finally {
		}					
	});
}

+ (void)closeFD:(int)theFD;
{
	if (theFD != -1)
	{
		int res = close(theFD);
		if (res == -1)
			NSLog(@"+[%@ %@] close() failed: %s", NSStringFromClass(self), NSStringFromSelector(_cmd), strerror(errno));
	}
}

- (id)worker:(NSDictionary*)theParams;
{
	return [NTDispatchSource workerClassMethod:[theParams objectForKey:@"desc"] proxy:[theParams objectForKey:@"proxy"]];
}

// wanted to be safe and avoid using any instance variables
+ (id)workerClassMethod:(NTFileDesc*)inDesc proxy:(NTMessageProxy*)inProxy;
{
	dispatch_source_t theSource = nil;
	
	if (![inDesc isPipe])
	{		
		int theFD = open([inDesc fileSystemPath], O_EVTONLY, 0);
		if (theFD != -1)
		{
			const NSUInteger sourceFlags = (DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE);  // not including DISPATCH_VNODE_LINK
			
			theSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
																 theFD,
																 sourceFlags, 
																 dispatch_get_main_queue());
			
			if (!theSource)
				[NTDispatchSource closeFD:theFD];
			else
			{				
				dispatch_set_context(theSource, [inProxy retain]);
				
				dispatch_source_set_event_handler(theSource, ^{
					@try {
						NTMessageProxy* theProxy = (NTMessageProxy*)dispatch_get_context(theSource);

						[theProxy notify:nil];
					}
					@catch (NSException * e) {
						NSLog(@"dispatch_source_set_event_handler exception: %@", e);
					}
					@finally {
					}
				});
				
				// Install a cancellation handler to free the descriptor
				// and the stored string.
				dispatch_source_set_cancel_handler(theSource, ^{
					@try {
						// we are on the main queue, so do it async just to keep it off the main thread
						[NTDispatchSource closeFDAsync:theFD];
						
						NTMessageProxy* theProxy = (NTMessageProxy*)dispatch_get_context(theSource);
						[theProxy release];
					}
					@catch (NSException * e) {
						NSLog(@"dispatch_source_set_cancel_handler exception: %@", e);
					}
					@finally {
					}					
				});
				
				// Start processing events.
				dispatch_resume(theSource);
			}
		}
	}
	
	return [NSValue valueWithPointer:theSource];
}

- (void)worker_result:(id)theDispatchSourceValue;
{
	self.dispatchSource = [theDispatchSourceValue pointerValue];
}

- (NSString*)description; 
{ 
	return [NSString stringWithFormat:@"%@ : %@", NSStringFromClass([self class]), [self.descriptionDesc path]]; 
} 

@end

