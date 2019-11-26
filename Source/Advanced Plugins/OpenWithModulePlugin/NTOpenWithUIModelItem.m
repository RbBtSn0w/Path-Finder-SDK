//
//  NTOpenWithUIModelItem.m
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 3/3/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTOpenWithUIModelItem.h"

@implementation NTOpenWithUIModelItem

@synthesize desc;
@synthesize command;
@synthesize title;

+ (NTOpenWithUIModelItem*)item:(NTFileDesc*)desc;
{
	NTOpenWithUIModelItem* result = [[NTOpenWithUIModelItem alloc] init];
	
	[result setDesc:desc];
	
	return [result autorelease];
}

+ (NTOpenWithUIModelItem*)separator;
{
	return [self item:nil];
}

+ (NTOpenWithUIModelItem*)itemWithCommand:(int)command title:(NSString*)title;
{
	NTOpenWithUIModelItem* result = [self item:nil];
	
	[result setCommand:command];
	[result setTitle:title];
	
	return result;  // already autoreleased
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    self.desc = nil;
    self.title = nil;
    [super dealloc];
}

- (NSComparisonResult)compareByName:(NTOpenWithUIModelItem *)fsi
{
    return ([[self desc] compareByDisplayName:[fsi desc]]);
}

// for sorting and locating the selected object
- (BOOL)isEqual:(NTOpenWithUIModelItem *)right;
{
	return [[self description] isEqualToString:[right description]];
}

- (NSComparisonResult)compare:(NTOpenWithUIModelItem *)right;
{
	return [[self description] compare:[right description]];
}

- (NSString*)description;
{
	if ([self title])
		return [self title];
	
	// this funky string is converted in the applications NSMenuItemHack class 
	if ([self desc])
		return [NSString stringWithFormat:@"::$$%@$$%d", [[self desc] path], kSmallMenuIconSize];
	
	// separator item
	return [NSString stringWithFormat:@"::$$%@$$%d", @"-", kSmallMenuIconSize];
}

@end
