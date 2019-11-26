//
//  NTFileSystemEventListener.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/27/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTStreamMessageProxy;

@interface NTFileSystemEventListener : NSObject 
{
	FSEventStreamRef streamRef;
	NTStreamMessageProxy* messageProxy;
	
	NTMessageProxy* delegateProxy;
}

+ (NTFileSystemEventListener*)eventListener:(NTMessageProxy*)theDelegateProxy dispatchQueue:(dispatch_queue_t)dispatchQueue;

@end
