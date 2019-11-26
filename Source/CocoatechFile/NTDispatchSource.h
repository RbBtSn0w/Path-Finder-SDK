//
//  NTDispatchSource.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTDispatchSource : NSObject 
{
	dispatch_source_t dispatchSource;
	NTFileDesc* descriptionDesc;
}

+ (NTDispatchSource*)source:(NTFileDesc*)theDesc delegateProxy:(NTMessageProxy*)theProxy;

@end
