//
//  NTFileDesc-State.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc-State.h"
#import "NTFileDesc-Private.h"
#import "NTFileDescData.h"

// a quick check to see if we have the icon information yet
// this is used for situations for speed where we want to draw what we have and not delay the main thread getting more stuff off the disk (or network)

@implementation NTFileDesc (State)

- (BOOL)itemInfo_initialized;
{
	return [cachedData itemInfo_initialized:nil];
}

- (BOOL)hasDirectoryContents_initialized;
{
	return [cachedData hasDirectoryContents_initialized:nil];
}

- (BOOL)displayName_initialized;
{
	return [cachedData displayName_initialized:nil];
}

- (BOOL)attributeDate_initialized;
{
	return [cachedData attributeDate_initialized:nil];
}

- (BOOL)creationDate_initialized;
{
	return [cachedData creationDate_initialized:nil];
}

- (BOOL)comments_initialized;
{
	return [cachedData comments_initialized:nil];
}

- (BOOL)modificationDate_initialized;
{
	return [cachedData modificationDate_initialized:nil];
}

- (BOOL)kindString_initialized;
{
	return [cachedData kind_initialized:nil];
}

- (BOOL)icon_intialized;
{
	return [cachedData icon_initialized:nil];
}

- (BOOL)iconImage_intialized;
{
	return [cachedData iconImage_initialized:nil];
}

// a quick check to see if we have the information yet
// this is used for situations for speed where we want to draw what we have and not delay the main thread getting more stuff off the disk (or network)
- (BOOL)size_initialized;
{
	if ([self isFile])
		return [cachedData fileSize_initialized:nil];
	
	return NO;
}

- (BOOL)physicalSize_initialized;
{
	if ([self isFile])
		return [cachedData physicalFileSize_initialized:nil];
	
	return NO;
}

@end
