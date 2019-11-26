//
//  NTOpenWithUIModel.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTOpenWithUIModelItem.h"

#define kChoosePopupCommand 44

@interface NTOpenWithUIModel : NSObject 
{
	BOOL initialized;
	BOOL changeAllEnabled;
	
	NSArray* descs;
	NSArray* mItems;
	id mSelectedItem;
	BOOL updatingUI;
}

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, assign) BOOL changeAllEnabled;
@property (nonatomic, retain) NSArray* descs;

+ (NTOpenWithUIModel*)model;

- (NTFileDesc*)firstDesc;

- (NSArray *)items;
- (void)setItems:(NSArray *)theItems;

- (id)selectedItem;
- (void)setSelectedItem:(id)theSelectedItem;

@end

