//
//  NTFileSystemEventListener.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/27/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTFileSystemEventListener.h"
#import "NTFileSystemEventMessage.h"
#import "NTVolume.h"
#import "NTStreamMessageProxy.h"
#include <sys/stat.h>

@interface NTFileSystemEventListener ()
@property (nonatomic, assign) FSEventStreamRef streamRef;
@property (nonatomic, retain) NTStreamMessageProxy *messageProxy;
@property (nonatomic, retain) NTMessageProxy *delegateProxy;
@end

static void fsevents_callback(FSEventStreamRef streamRef,
							  void *clientCallBackInfo, 
							  int numEvents,
							  NSArray *eventPaths, 
							  const FSEventStreamEventFlags *eventMasks, 
							  const uint64_t *eventIDs);

@interface NTFileSystemEventListener (Protocols) <NTMessageProxyProtocol>
@end

@interface NTFileSystemEventListener (Private)
- (FSEventStreamRef)makeStreamRef;
- (void)start:(dispatch_queue_t)dispatchQueue;
@end

@implementation NTFileSystemEventListener

@synthesize streamRef;
@synthesize messageProxy, delegateProxy;

+ (NTFileSystemEventListener*)eventListener:(NTMessageProxy*)theDelegateProxy dispatchQueue:(dispatch_queue_t)dispatchQueue;
{	
	NTFileSystemEventListener* result = [[NTFileSystemEventListener alloc] init];
		
	result.delegateProxy = theDelegateProxy;
	[result start:dispatchQueue];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	if (self.streamRef)
	{
		FSEventStreamStop(self.streamRef);
		FSEventStreamInvalidate(self.streamRef);
		FSEventStreamRelease(self.streamRef);
		self.streamRef = nil;
	}
	
	self.delegateProxy = nil;
	
	[self.messageProxy invalidate];
	self.messageProxy = nil;
	
    [super dealloc];
}

@end

@implementation NTFileSystemEventListener (Private)

- (void)start:(dispatch_queue_t)dispatchQueue;
{
	self.messageProxy = [NTStreamMessageProxy streamProxy:self];
	
	FSEventStreamRef ref = [self makeStreamRef];
	if (ref)
	{
		self.streamRef = ref;
		
		FSEventStreamSetDispatchQueue(self.streamRef, dispatchQueue);
		
		Boolean startedOK = FSEventStreamStart(self.streamRef);
		if (!startedOK)
			NSLog(@"-[%@ %@] FSEventStreamStart failed", [self className], NSStringFromSelector(_cmd));
	}
}

- (FSEventStreamRef)makeStreamRef;
{
	FSEventStreamRef theStreamRef = NULL;
	CFMutableArrayRef cfArray;
	FSEventStreamContext  context = {0, self.messageProxy, proxyRetain, proxyRelease, NULL};
	
	cfArray = CFArrayCreateMutable(kCFAllocatorDefault, 1, &kCFTypeArrayCallBacks);	
	
	if (cfArray)
	{
		CFArraySetValueAtIndex(cfArray, 0, (CFStringRef)@"/");
		
		// network volumes need this
		theStreamRef = FSEventStreamCreate(kCFAllocatorDefault,
										   (FSEventStreamCallback)&fsevents_callback,
										   &context,
										   cfArray,
										   kFSEventStreamEventIdSinceNow, // since when
										   .1, // latency
										   kFSEventStreamCreateFlagUseCFTypes);
		
		CFRelease(cfArray);
	}
	
	if (theStreamRef)
		return theStreamRef;
	
	NSLog(@"-[%@ %@] FSEventStreamCreate failed: %@", [self className], NSStringFromSelector(_cmd), @"/");
	
	return nil;
}

@end

@implementation NTFileSystemEventListener (Protocols)

// NTMessageProxyProtocol
- (void)messageProxy:(NTMessageProxy*)theProxy message:(id)theMessage;
{
	[self.delegateProxy notify:theMessage];
}

@end

// ----------------------------------------------------------------------------
// callback

static void fsevents_callback(FSEventStreamRef streamRef,
							  void *clientCallBackInfo, 
							  int numEvents,
							  NSArray *eventPaths, 
							  const FSEventStreamEventFlags *eventMasks, 
							  const uint64_t *eventIDs)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	{
		NTStreamMessageProxy* theMessageProxy = (NTStreamMessageProxy*)clientCallBackInfo;
		NSMutableArray* theMessages = [NSMutableArray array];
		NSUInteger cnt=0;
		NSUInteger i;
		
		for (NSString* thePath in eventPaths)
		{			
			i = cnt++;

			// remove any trailing "/"
			if ([thePath length] > 1)
			{
				if ([thePath hasSuffix:@"/"])
					thePath = [thePath stringByDeletingSuffix:@"/"];
			}
			
			BOOL rescanSubdirectories = NO;
			if (eventMasks[i] & kFSEventStreamEventFlagMustScanSubDirs) 
				rescanSubdirectories = YES;
			else if (eventMasks[i] & kFSEventStreamEventFlagUserDropped) 
				rescanSubdirectories = YES;
			else if (eventMasks[i] & kFSEventStreamEventFlagKernelDropped) 
				rescanSubdirectories = YES;
			
			[theMessages addObject:[NTFileSystemEventMessage message:thePath rescanSubdirectories:rescanSubdirectories]];
		}
		
		[theMessageProxy notify:theMessages];
	}
	[pool release];
	pool = nil;
}
