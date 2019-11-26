//
//  NTOpenWithUIModelItem.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 3/3/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTOpenWithUIModelItem : NSObject
{
	NTFileDesc* desc;

	int command;
	NSString* title;
}

@property (nonatomic, retain) NTFileDesc *desc;
@property (nonatomic, assign) int command;
@property (nonatomic, retain) NSString *title;

+ (NTOpenWithUIModelItem*)item:(NTFileDesc*)desc;
+ (NTOpenWithUIModelItem*)separator;
+ (NTOpenWithUIModelItem*)itemWithCommand:(int)command title:(NSString*)title;

@end

