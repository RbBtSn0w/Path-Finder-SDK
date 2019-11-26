//
//  NTDispatchSourceItem.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTDispatchSourceItem.h"

@interface NTDispatchSourceItem ()
@property (nonatomic, retain) NTFileDesc *desc;
@property (nonatomic, retain) NSString* identifier_storage;
@property (nonatomic, assign) BOOL monitorWithFSEvents;
@end

@interface NTDispatchSourceItem (Private)
- (NSString*)buildIdentifier;
@end

@implementation NTDispatchSourceItem

@synthesize desc;
@synthesize identifier_storage, monitorWithFSEvents;

+ (NTDispatchSourceItem*)item:(NTFileDesc*)theDesc;
{
	NTDispatchSourceItem* result = [[NTDispatchSourceItem alloc] init];
	
	result.desc = theDesc;
		
	// if an item on a network volume, we should watch parent
	// kqueues on network files locks out writing
	if (![theDesc isVolume] && [theDesc isNetwork])
		result.monitorWithFSEvents = YES;
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    self.desc = nil;
    self.identifier_storage = nil;
	
    [super dealloc];
}

- (NSString*)identifier;
{
	@synchronized(self) {
		if (!self.identifier_storage)
			self.identifier_storage = [self buildIdentifier];
	}
	
	return self.identifier_storage;
}

@end

@implementation NTDispatchSourceItem (Private)

- (NSString*)buildIdentifier;
{
	if ([self.desc isComputer])
		return @"Computer";
	
	// using path and nodeID to make sure it's the exact same file we be talkin bout
	return [NSString stringWithFormat:@"%@:%d:%d", [self.desc path], [self.desc nodeID], (int)self.monitorWithFSEvents];
}

@end
