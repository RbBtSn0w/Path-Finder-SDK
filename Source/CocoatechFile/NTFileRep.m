//
//  NTFileRep.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/30/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "NTFileRep.h"
#import "NTVolume.h"

// represents a file.  Used for restoring selection.
@interface NTFileRep ()
@property (nonatomic, assign) UInt32 nodeID;
@property (nonatomic, assign) BOOL isVolume;
@property (nonatomic, assign) BOOL isDirectory;
@property (nonatomic, assign) FSVolumeRefNum volumeRefNum;
@property (nonatomic, retain) NSString* displayName;

@property (nonatomic, retain) NSURL *volumeURL;
@property (nonatomic, assign) UInt64 volumeCapacity;
@property (nonatomic, retain) NSString *volumeUniqueID;
@end

@implementation NTFileRep

@synthesize nodeID, volumeRefNum, isVolume;
@synthesize displayName, isDirectory;
@synthesize volumeURL;
@synthesize volumeCapacity, volumeUniqueID;

+ (NSArray*)reps:(NSArray*)theDescs;
{
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[theDescs count]];
	
	for (NTFileDesc* theDesc in theDescs)
		[result addObject:[NTFileRep rep:theDesc]];
	
	return result;
}

+ (NTFileRep*)rep:(NTFileDesc*)theDesc;
{
	NTFileRep* result = [[NTFileRep alloc] init];
	
	result.nodeID = [theDesc nodeID];
	result.displayName = [theDesc displayName];
	result.isDirectory = [theDesc isDirectory];
	
	// volumes return fsRtDirID for nodeID, so it's not unique
	result.isVolume = [theDesc isVolume];
	if (result.isVolume)
	{
		result.volumeRefNum = [theDesc volumeRefNum];		
		result.volumeURL = [theDesc URL];
		result.volumeCapacity = [[theDesc volume] totalBytes];
		result.volumeUniqueID = [[theDesc volume] volumeUniqueID];
	}
	
	return [result autorelease];
}

- (id)initWithCoder:(NSCoder *)coder 
{
	if (self = [self init])
    {			
		self.nodeID = [coder decodeInt32ForKey:@"nodeID"];
		self.volumeRefNum = [coder decodeInt32ForKey:@"volumeRefNum"];
		self.isVolume = [coder decodeBoolForKey:@"isVolume"];
		self.displayName = [coder decodeObjectForKey:@"displayName"];
		
		self.volumeURL = [coder decodeObjectForKey:@"volumeURL"];
		self.volumeCapacity = [coder decodeInt64ForKey:@"volumeCapacity"];
		self.volumeUniqueID = [coder decodeObjectForKey:@"volumeUniqueID"];
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder 
{	
	[coder encodeInt32:self.nodeID forKey:@"nodeID"];
	[coder encodeInt32:self.volumeRefNum forKey:@"volumeRefNum"];
	[coder encodeBool:self.isVolume forKey:@"isVolume"];
    [coder encodeObject:self.displayName forKey:@"displayName"];

    [coder encodeObject:self.volumeURL forKey:@"volumeURL"];
    [coder encodeInt64:self.volumeCapacity forKey:@"volumeCapacity"];
    [coder encodeObject:self.volumeUniqueID forKey:@"volumeUniqueID"];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.displayName = nil;
	self.volumeURL = nil;
	self.volumeUniqueID = nil;
	
    [super dealloc];
}

// typically you would first try nodeID since that handles renamed files
- (BOOL)matchesNodeID:(NTFileDesc*)theDesc;
{	
	if (self.isVolume)
	{
		if ([theDesc isVolume])
		{
			NSString* rightUUID = [[theDesc volume] volumeUniqueID];
			if (self.volumeUniqueID && rightUUID)
				return [self.volumeUniqueID isEqualToString:rightUUID];
			
			NSURL *rightURL = [theDesc URL];
			if (self.volumeURL && rightURL)
			{
				if ([rightURL isEqual:self.volumeURL])
					return [[theDesc volume] totalBytes] == self.volumeCapacity;
			}
			
			// old way compared volumeRefNums which change on each mount
			return (self.volumeRefNum == [theDesc volumeRefNum]);
		}
	}
	else
		return (self.nodeID == [theDesc nodeID]);
	
	return NO;
}

// if not found by nodeID, it might have been a safe saved file, so find a matching displayName
- (BOOL)matchesDisplayName:(NTFileDesc*)theDesc;
{	
	BOOL result = [[theDesc displayName] isEqualToString:self.displayName];
	
	// extra check to make sure we avoid conflicting displayNames
	// didn't use name since name is much slower
	if (result)
		result = ((self.isDirectory == [theDesc isDirectory]) && (self.isVolume == [theDesc isVolume]));
	
	return result;
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"nodeID:%d vRefNum:%d isVolume:%@ name:%@ volURL:%@ volCap:%lu", self.nodeID, self.volumeRefNum, self.isVolume ? @"YES":@"NO", self.displayName, self.volumeURL, self.volumeCapacity];
}

// used externally, accurateMatchKey returns a combo nodeID or vrefNum string to use for matching
// guessMatchKey returns the displayName for inaccurate matching
- (NSString*)accurateMatchKey;
{
	if (self.isVolume)
	{
		if (self.volumeUniqueID)
			return [NSString stringWithFormat:@"av:%@", self.volumeUniqueID];
		else
			return [NSString stringWithFormat:@"av:%@:%lu", self.volumeURL, self.volumeCapacity];
	}
	
	return [NSString stringWithFormat:@"an:%d", self.nodeID];
}

- (NSString*)guessMatchKey;
{
	return [NSString stringWithFormat:@"g:%@:%@", self.displayName, self.isDirectory ? @"y":@"n"];
}

- (BOOL)isEqual:(NTFileRep*)right;
{
	if (self.nodeID == right.nodeID)
	{
		if (self.volumeRefNum == right.volumeRefNum)
		{
			if (self.isVolume == right.isVolume)
			{
				if ([self.displayName isEqualToString:right.displayName])
					return YES;
			}
		}
	}
	
	return NO;
}

- (NSUInteger)hash;
{
	return [[self description] hash];
}

@end
