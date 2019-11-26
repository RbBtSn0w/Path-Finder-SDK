//
//  NTDirMonitorItem.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/11/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTDirMonitorItem.h"

@interface NTDirMonitorItem ()
@property (nonatomic, retain) NTFileDesc *desc; 
@property (nonatomic, retain) NTFileDesc *parentDesc; 
@property (nonatomic, retain) NSString* identifier_storage;
@property (nonatomic, assign) BOOL networkVolume; 
@end

@interface NTDirMonitorItem (Private)
- (NSString*)buildIdentifier;
@end

@implementation NTDirMonitorItem

@synthesize desc, parentDesc;
@synthesize identifier_storage, networkVolume;

+ (NTDirMonitorItem*)item:(NTFileDesc*)theDesc;
{
	NTDirMonitorItem* result = [[NTDirMonitorItem alloc] init];
	
	result.desc = theDesc;
	result.networkVolume = [theDesc isNetwork];
	result.parentDesc = [theDesc parentDesc];
	
	return [result autorelease];
}

- (NSString*)identifier;
{
	@synchronized(self) {
		if (!self.identifier_storage)
			self.identifier_storage = [self buildIdentifier];
	}
	
	return self.identifier_storage;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    self.desc = nil;
    self.parentDesc = nil;
    self.identifier_storage = nil;
	
    [super dealloc];
}

@end

@implementation NTDirMonitorItem (Private)

- (NSString*)buildIdentifier;
{
	if ([self.desc isComputer])
		return @"Computer";
	
	// using path and nodeID to make sure it's the exact same file we be talkin bout
	// using parentDesc since we want to reuse the same folder watcher for all requests to this parent folder
	return [NSString stringWithFormat:@"%@:%d", [self.parentDesc path], [self.parentDesc nodeID]];
}

@end
