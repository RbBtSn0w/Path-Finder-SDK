//
//  NTDirMonitorItem.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/11/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTDirMonitorItem : NSObject {
	NTFileDesc* desc;
	NTFileDesc* parentDesc;
	BOOL networkVolume;
	NSString* identifier_storage;
}

@property (readonly, nonatomic, retain) NTFileDesc *desc;
@property (readonly, nonatomic, retain) NTFileDesc *parentDesc;
@property (readonly, nonatomic, assign) BOOL networkVolume; 

+ (NTDirMonitorItem*)item:(NTFileDesc*)theDesc;

- (NSString*)identifier;

@end
