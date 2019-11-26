//
//  NTStreamMessageProxy.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/22/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTStreamMessageProxy : NTMessageProxy
{
}

+ (NTStreamMessageProxy*)streamProxy:(id<NTMessageProxyProtocol>)target;

@end

// used in FSEventStreamContext
// I'm assuming it's more robust if I allow the stream to retain and release us when it knows it's done processing messages
const void * proxyRetain(const void *info);
void proxyRelease(const void *info);
