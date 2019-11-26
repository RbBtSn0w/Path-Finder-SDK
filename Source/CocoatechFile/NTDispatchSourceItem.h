//
//  NTDispatchSourceItem.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTDispatchSourceItem : NSObject {
	NTFileDesc* desc;
	NSString* identifier_storage;
	BOOL monitorWithFSEvents;
}

@property (readonly, nonatomic, retain) NTFileDesc *desc;
@property (readonly, nonatomic, assign) BOOL monitorWithFSEvents;

- (NSString*)identifier;

+ (NTDispatchSourceItem*)item:(NTFileDesc*)theDesc;

@end
