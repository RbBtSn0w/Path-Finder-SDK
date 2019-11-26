//
//  NTDispatchFSESource.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/11/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc,NTDirMonitorItem, NTDispatchFSESource;

@interface NTDispatchFSESource : NSObject 
{
	NTMessageProxy* delegateProxy;
    NTFileDesc* desc;
	NTMessageProxy *proxy;
	NTDirMonitorItem *sourceItem;
}

+ (NTDispatchFSESource*)source:(NTFileDesc*)desc delegateProxy:(NTMessageProxy*)delegateProxy;

@end
