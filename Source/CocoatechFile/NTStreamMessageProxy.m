//
//  NTStreamMessageProxy.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/22/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTStreamMessageProxy.h"

@implementation NTStreamMessageProxy

+ (NTStreamMessageProxy*)streamProxy:(id<NTMessageProxyProtocol>)target;
{
	NTStreamMessageProxy* result = (NTStreamMessageProxy*)[self proxy:target];
		
	return result;  // already autoreleased
}

- (void)dealloc;
{
	[super dealloc];
}

@end

// used in FSEventStreamContext
const void * proxyRetain(const void *info)
{
	return [(id)info retain];
}

// used in FSEventStreamContext
void proxyRelease(const void *info)
{
	[(id)info release];
}
