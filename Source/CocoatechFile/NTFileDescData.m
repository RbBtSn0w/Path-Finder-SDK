//
//  NTFileDescData.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileDescData.h"

@interface NTFileDescData ()
@property (retain, nonatomic) NTObjectContainer* cache;
@property (retain, nonatomic) NTUInt64Container* cache64;
@property (retain, nonatomic) NTUInt32Container* cache32;
@end

enum
{
	displayName_cacheIndex,
	kind_cacheIndex,
	icon_cacheIndex,
	modificationDate_cacheIndex,
	creationDate_cacheIndex,
	lastUsedDate_cacheIndex,
	attributeDate_cacheIndex,
	accessDate_cacheIndex,
	dictionaryKey_cacheIndex,
	strictDictionaryKey_cacheIndex,
	architecture_cacheIndex,
	extension_cacheIndex,
	version_cacheIndex,
	bundleVersion_cacheIndex,
	getInfo_cacheIndex,
	application_cacheIndex,
	comments_cacheIndex,
	cachedURL_cacheIndex,
	permissionString_cacheIndex,
	ownerName_cacheIndex,
	groupName_cacheIndex,
	uniformTypeID_cacheIndex,
	bundleSignature_cacheIndex,
	bundleIdentifier_cacheIndex,
	itemInfo_cacheIndex,
	volume_cacheIndex,
	typeIdentifier_cacheIndex,
	metadata_cacheIndex,
	resolvedDesc_cacheIndex,
	originalAliasFilePath_cacheIndex,
	iconImage_cacheIndex,
	LAST_cacheIndex,
};

enum
{
	fileSize_cacheIndex64,
	physicalFileSize_cacheIndex64,
	rsrcForkSize_cacheIndex64,
	dataForkSize_cacheIndex64,
	rsrcForkPhysicalSize_cacheIndex64,
	dataForkPhysicalSize_cacheIndex64,	
};

enum
{
	vRefNum_cacheIndex32,
	posixPermissions_cacheIndex32,
	posixFileMode_cacheIndex32,
	valence_cacheIndex32,
	creator_cacheIndex32,
	type_cacheIndex32,
	label_cacheIndex32,
	groupID_cacheIndex32,
	ownerID_cacheIndex32,
	nodeID_cacheIndex32,
	parentDirID_cacheIndex32,
};

@implementation NTFileDescData

@synthesize cache, cache64, cache32;

- (id)init;
{
	self = [super init];
	
	// avoiding the autorelease pool
	NTObjectContainer* container = [[NTObjectContainer alloc] initWithCap:6 mapCap:LAST_cacheIndex];
	self.cache = container;
	[container release];

	NTUInt32Container* container32 = [[NTUInt32Container alloc] initWithCap:3 mapCap:3];
	self.cache32 = container32;
	[container32 release];

	NTUInt64Container* container64 = [[NTUInt64Container alloc] initWithCap:1 mapCap:1];
	self.cache64 = container64;
	[container64 release];

	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	self.cache = nil;
	self.cache32 = nil;
	self.cache64 = nil;
	
    [super dealloc];
}

//---------------------------------------------------------- 
//  displayName 
//---------------------------------------------------------- 

- (BOOL)displayName_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.displayName_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:displayName_cacheIndex];
		}
	}
	
	return result;
}

- (void)setDisplayName:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.displayName_initialized)
		{
			flags.displayName_initialized = YES;
			
			[cache setObj:value atIndex:displayName_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  iconImage 
//---------------------------------------------------------- 

- (BOOL)iconImage_initialized:(NSImage**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.iconImage_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:iconImage_cacheIndex];
		}
	}
	
	return result;
}

- (void)setIconImage:(NSImage*)value;
{
	@synchronized(cache) {
		if (!flags.iconImage_initialized)
		{
			flags.iconImage_initialized = YES;
			
			[cache setObj:value atIndex:iconImage_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  isFile
//---------------------------------------------------------- 

- (BOOL)isFile_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isFile_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsFile;
		}
	}
	
	return result;	
}

- (void)setIsFile:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isFile_initialized)
		{
			flags.isFile_initialized = YES;
			bools.cachedIsFile = value;
		}
	}	
}

//---------------------------------------------------------- 
//  kind
//---------------------------------------------------------- 

- (BOOL)kind_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.kind_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:kind_cacheIndex];
		}
	}
	
	return result;
}

- (void)setKind:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.kind_initialized)
		{
			flags.kind_initialized = YES;
			[cache setObj:value atIndex:kind_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}		
	}
}

//---------------------------------------------------------- 
//  architecture
//---------------------------------------------------------- 

- (BOOL)architecture_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.architecture_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:architecture_cacheIndex];
		}
	}
	
	return result;
}

- (void)setArchitecture:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.architecture_initialized)
		{
			flags.architecture_initialized = YES;
			[cache setObj:value atIndex:architecture_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}		
	}
}

//---------------------------------------------------------- 
//  extension
//---------------------------------------------------------- 

- (BOOL)extension_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.extension_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:extension_cacheIndex];
		}
	}
	
	return result;
}

- (void)setExtension:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.extension_initialized)
		{
			flags.extension_initialized = YES;
			[cache setObj:value atIndex:extension_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}		
	}
}

//---------------------------------------------------------- 
//  icon
//---------------------------------------------------------- 

- (BOOL)icon_initialized:(NTIcon**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.icon_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:icon_cacheIndex];
		}
	}
	
	return result;
}

- (void)setIcon:(NTIcon*)value;
{
	@synchronized(cache) {
		if (!flags.icon_initialized)
		{
			flags.icon_initialized = YES;
			[cache setObj:value atIndex:icon_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  modificationDate 
//---------------------------------------------------------- 

- (BOOL)modificationDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.modificationDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:modificationDate_cacheIndex];
		}
	}
	
	return result;
}

- (void)setModificationDate:(NSDate*)value;
{
	@synchronized(cache) {
		if (!flags.modificationDate_initialized)
		{
			flags.modificationDate_initialized = YES;
			[cache setObj:value atIndex:modificationDate_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  creationDate 
//---------------------------------------------------------- 

- (BOOL)creationDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.creationDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:creationDate_cacheIndex];
		}
	}
	
	return result;
}

- (void)setCreationDate:(NSDate*)value;
{
	@synchronized(cache) {
		if (!flags.creationDate_initialized)
		{
			flags.creationDate_initialized = YES;
			[cache setObj:value atIndex:creationDate_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  lastUsedDate 
//---------------------------------------------------------- 

- (BOOL)lastUsedDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.lastUsedDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:lastUsedDate_cacheIndex];
		}
	}
	
	return result;
}

- (void)setLastUsedDate:(NSDate*)value;
{
	@synchronized(cache) {
		if (!flags.lastUsedDate_initialized)
		{
			flags.lastUsedDate_initialized = YES;
			[cache setObj:value atIndex:lastUsedDate_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  attributeDate 
//---------------------------------------------------------- 

- (BOOL)attributeDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.attributeDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:attributeDate_cacheIndex];
		}
	}
	
	return result;
}

- (void)setAttributeDate:(NSDate*)value;
{
	@synchronized(cache) {
		if (!flags.attributeDate_initialized)
		{
			flags.attributeDate_initialized = YES;
			[cache setObj:value atIndex:attributeDate_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  accessDate 
//---------------------------------------------------------- 

- (BOOL)accessDate_initialized:(NSDate**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.accessDate_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:accessDate_cacheIndex];
		}
	}
	
	return result;
}

- (void)setAccessDate:(NSDate*)value;
{
	@synchronized(cache) {
		if (!flags.accessDate_initialized)
		{
			flags.accessDate_initialized = YES;
			[cache setObj:value atIndex:accessDate_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  version 
//---------------------------------------------------------- 

- (BOOL)version_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.version_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:version_cacheIndex];
		}
	}
	
	return result;
}

- (void)setVersion:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.version_initialized)
		{
			flags.version_initialized = YES;
			[cache setObj:value atIndex:version_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  bundleVersion 
//---------------------------------------------------------- 

- (BOOL)bundleVersion_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.bundleVersion_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:bundleVersion_cacheIndex];
		}
	}
	
	return result;
}

- (void)setBundleVersion:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.bundleVersion_initialized)
		{
			flags.bundleVersion_initialized = YES;
			[cache setObj:value atIndex:bundleVersion_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  getInfo 
//---------------------------------------------------------- 

- (BOOL)getInfo_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.getInfo_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:getInfo_cacheIndex];
		}
	}
	
	return result;
}

- (void)setGetInfo:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.getInfo_initialized)
		{
			flags.getInfo_initialized = YES;
			[cache setObj:value atIndex:getInfo_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  application 
//---------------------------------------------------------- 

- (BOOL)application_initialized:(NTFileDesc**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.application_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:application_cacheIndex];
		}
	}
	
	return result;
}

- (void)setApplication:(NTFileDesc*)value;
{
	@synchronized(cache) {
		if (!flags.application_initialized)
		{
			flags.application_initialized = YES;
			[cache setObj:value atIndex:application_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  comments 
//---------------------------------------------------------- 

- (BOOL)comments_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.comments_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:comments_cacheIndex];
		}
	}
	
	return result;
}

- (void)setComments:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.comments_initialized)
		{
			flags.comments_initialized = YES;
			[cache setObj:value atIndex:comments_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  cachedURL 
//---------------------------------------------------------- 

- (BOOL)cachedURL_initialized:(NSURL**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.cachedURL_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:cachedURL_cacheIndex];
		}
	}
	
	return result;
}

- (void)setCachedURL:(NSURL*)value;
{
	@synchronized(cache) {
		if (!flags.cachedURL_initialized)
		{
			flags.cachedURL_initialized = YES;
			[cache setObj:value atIndex:cachedURL_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

- (void)removeCachedURL;
{
	@synchronized(cache) {
		if (flags.cachedURL_initialized)
		{
			flags.cachedURL_initialized = NO;
			
			// ultra thread safe, setObj does a release
			[[[cache objAtIndex:cachedURL_cacheIndex] retain] autorelease];
			
			[cache setObj:nil atIndex:cachedURL_cacheIndex];
		}
	}
}

//---------------------------------------------------------- 
//  dictionaryKey 
//---------------------------------------------------------- 

- (BOOL)dictionaryKey_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.dictionaryKey_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:dictionaryKey_cacheIndex];
		}
	}
	
	return result;
}

- (void)setDictionaryKey:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.dictionaryKey_initialized)
		{
			flags.dictionaryKey_initialized = YES;
			[cache setObj:value atIndex:dictionaryKey_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  strictDictionaryKey 
//---------------------------------------------------------- 

- (BOOL)strictDictionaryKey_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.strictDictionaryKey_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:strictDictionaryKey_cacheIndex];
		}
	}
	
	return result;
}

- (void)setStrictDictionaryKey:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.strictDictionaryKey_initialized)
		{
			flags.strictDictionaryKey_initialized = YES;
			[cache setObj:value atIndex:strictDictionaryKey_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  permissionString 
//---------------------------------------------------------- 

- (BOOL)permissionString_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.permissionString_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:permissionString_cacheIndex];
		}
	}
	
	return result;
}

- (void)setPermissionString:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.permissionString_initialized)
		{
			flags.permissionString_initialized = YES;
			[cache setObj:value atIndex:permissionString_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  ownerName 
//---------------------------------------------------------- 

- (BOOL)ownerName_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.ownerName_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:ownerName_cacheIndex];
		}
	}
	
	return result;
}

- (void)setOwnerName:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.ownerName_initialized)
		{
			flags.ownerName_initialized = YES;
			[cache setObj:value atIndex:ownerName_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  groupName 
//---------------------------------------------------------- 

- (BOOL)groupName_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.groupName_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:groupName_cacheIndex];
		}
	}
	
	return result;
}

- (void)setGroupName:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.groupName_initialized)
		{
			flags.groupName_initialized = YES;
			[cache setObj:value atIndex:groupName_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  uniformTypeID 
//---------------------------------------------------------- 

- (BOOL)uniformTypeID_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.uniformTypeID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:uniformTypeID_cacheIndex];
		}
	}
	
	return result;
}

- (void)setUniformTypeID:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.uniformTypeID_initialized)
		{
			flags.uniformTypeID_initialized = YES;
			[cache setObj:value atIndex:uniformTypeID_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  bundleSignature 
//---------------------------------------------------------- 

- (BOOL)bundleSignature_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.bundleSignature_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:bundleSignature_cacheIndex];
		}
	}
	
	return result;
}

- (void)setBundleSignature:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.bundleSignature_initialized)
		{
			flags.bundleSignature_initialized = YES;
			[cache setObj:value atIndex:bundleSignature_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  bundleIdentifier
//---------------------------------------------------------- 

- (BOOL)bundleIdentifier_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.bundleIdentifier_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:bundleIdentifier_cacheIndex];
		}
	}
	
	return result;
}

- (void)setBundleIdentifier:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.bundleIdentifier_initialized)
		{
			flags.bundleIdentifier_initialized = YES;
			[cache setObj:value atIndex:bundleIdentifier_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  itemInfo 
//---------------------------------------------------------- 

- (BOOL)itemInfo_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.itemInfo_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:itemInfo_cacheIndex];
		}
	}
	
	return result;
}

- (void)setItemInfo:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.itemInfo_initialized)
		{
			flags.itemInfo_initialized = YES;
			[cache setObj:value atIndex:itemInfo_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  volume 
//---------------------------------------------------------- 

- (BOOL)volume_initialized:(NTVolume**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.volume_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:volume_cacheIndex];
		}
	}
	
	return result;
}

- (void)setVolume:(NTVolume*)value;
{
	@synchronized(cache) {
		if (!flags.volume_initialized)
		{
			flags.volume_initialized = YES;
			[cache setObj:value atIndex:volume_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  typeIdentifier 
//---------------------------------------------------------- 

- (BOOL)typeIdentifier_initialized:(NTFileTypeIdentifier**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.typeIdentifier_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:typeIdentifier_cacheIndex];
		}
	}
	
	return result;
}

- (void)setTypeIdentifier:(NTFileTypeIdentifier*)value;
{
	@synchronized(cache) {
		if (!flags.typeIdentifier_initialized)
		{
			flags.typeIdentifier_initialized = YES;
			[cache setObj:value atIndex:typeIdentifier_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  isPackage
//---------------------------------------------------------- 

- (BOOL)isPackage_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isPackage_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsPackage;
		}
	}
	
	return result;	
}

- (void)setIsPackage:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isPackage_initialized)
		{
			flags.isPackage_initialized = YES;
			bools.cachedIsPackage = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isApplication
//---------------------------------------------------------- 

- (BOOL)isApplication_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isApplication_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsApplication;
		}
	}
	
	return result;	
}

- (void)setIsApplication:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isApplication_initialized)
		{
			flags.isApplication_initialized = YES;
			bools.cachedIsApplication = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isCarbonAlias
//---------------------------------------------------------- 

- (BOOL)isCarbonAlias_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isCarbonAlias_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsCarbonAlias;
		}
	}
	
	return result;	
}

- (void)setIsCarbonAlias:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isCarbonAlias_initialized)
		{
			flags.isCarbonAlias_initialized = YES;
			bools.cachedIsCarbonAlias = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isPathFinderAlias
//---------------------------------------------------------- 

- (BOOL)isPathFinderAlias_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isPathFinderAlias_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsPathFinderAlias;
		}
	}
	
	return result;	
}

- (void)setIsPathFinderAlias:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isPathFinderAlias_initialized)
		{
			flags.isPathFinderAlias_initialized = YES;
			bools.cachedIsPathFinderAlias = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isSymbolicLink
//---------------------------------------------------------- 

- (BOOL)isSymbolicLink_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isSymbolicLink_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsSymbolicLink;
		}
	}
	
	return result;	
}

- (void)setIsSymbolicLink:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isSymbolicLink_initialized)
		{
			flags.isSymbolicLink_initialized = YES;
			bools.cachedIsSymbolicLink = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isInvisible
//---------------------------------------------------------- 

- (BOOL)isInvisible_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isInvisible_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsInvisible;
		}
	}
	
	return result;	
}

- (void)setIsInvisible:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isInvisible_initialized)
		{
			flags.isInvisible_initialized = YES;
			bools.cachedIsInvisible = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isExtensionHidden
//---------------------------------------------------------- 

- (BOOL)isExtensionHidden_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isExtensionHidden_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsExtensionHidden;
		}
	}
	
	return result;	
}

- (void)setIsExtensionHidden:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isExtensionHidden_initialized)
		{
			flags.isExtensionHidden_initialized = YES;
			bools.cachedIsExtensionHidden = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isLocked
//---------------------------------------------------------- 

- (BOOL)isLocked_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isLocked_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsLocked;
		}
	}
	
	return result;	
}

- (void)setIsLocked:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isLocked_initialized)
		{
			flags.isLocked_initialized = YES;
			bools.cachedIsLocked = value;
		}
	}	
}

//---------------------------------------------------------- 
//  hasCustomIcon
//---------------------------------------------------------- 

- (BOOL)hasCustomIcon_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.hasCustomIcon_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedHasCustomIcon;
		}
	}
	
	return result;	
}

- (void)setHasCustomIcon:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.hasCustomIcon_initialized)
		{
			flags.hasCustomIcon_initialized = YES;
			bools.cachedHasCustomIcon = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isStationery
//---------------------------------------------------------- 

- (BOOL)isStationery_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isStationery_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsStationery;
		}
	}
	
	return result;	
}

- (void)setIsStationery:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isStationery_initialized)
		{
			flags.isStationery_initialized = YES;
			bools.cachedIsStationery = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isBundleBitSet
//---------------------------------------------------------- 

- (BOOL)isBundleBitSet_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isBundleBitSet_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsBundleBitSet;
		}
	}
	
	return result;	
}

- (void)setIsBundleBitSet:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isBundleBitSet_initialized)
		{
			flags.isBundleBitSet_initialized = YES;
			bools.cachedIsBundleBitSet = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isAliasBitSet
//---------------------------------------------------------- 

- (BOOL)isAliasBitSet_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isAliasBitSet_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsAliasBitSet;
		}
	}
	
	return result;	
}

- (void)setIsAliasBitSet:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isAliasBitSet_initialized)
		{
			flags.isAliasBitSet_initialized = YES;
			bools.cachedIsAliasBitSet = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isReadable
//---------------------------------------------------------- 

- (BOOL)isReadable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isReadable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsReadable;
		}
	}
	
	return result;	
}

- (void)setIsReadable:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isReadable_initialized)
		{
			flags.isReadable_initialized = YES;
			bools.cachedIsReadable = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isWritable
//---------------------------------------------------------- 

- (BOOL)isWritable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isWritable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsWritable;
		}
	}
	
	return result;	
}

- (void)setIsWritable:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isWritable_initialized)
		{
			flags.isWritable_initialized = YES;
			bools.cachedIsWritable = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isExecutable
//---------------------------------------------------------- 

- (BOOL)isExecutable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isExecutable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsExecutable;
		}
	}
	
	return result;	
}

- (void)setIsExecutable:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isExecutable_initialized)
		{
			flags.isExecutable_initialized = YES;
			bools.cachedIsExecutable = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isDeletable
//---------------------------------------------------------- 

- (BOOL)isDeletable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isDeletable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsDeletable;
		}
	}
	
	return result;	
}

- (void)setIsDeletable:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isDeletable_initialized)
		{
			flags.isDeletable_initialized = YES;
			bools.cachedIsDeletable = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isRenamable
//---------------------------------------------------------- 

- (BOOL)isRenamable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isRenamable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsRenamable;
		}
	}
	
	return result;	
}

- (void)setIsRenamable:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isRenamable_initialized)
		{
			flags.isRenamable_initialized = YES;
			bools.cachedIsRenamable = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isReadOnly
//---------------------------------------------------------- 

- (BOOL)isReadOnly_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isReadOnly_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsReadOnly;
		}
	}
	
	return result;	
}

- (void)setIsReadOnly:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isReadOnly_initialized)
		{
			flags.isReadOnly_initialized = YES;
			bools.cachedIsReadOnly = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isMovable
//---------------------------------------------------------- 

- (BOOL)isMovable_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isMovable_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsMovable;
		}
	}
	
	return result;	
}

- (void)setIsMovable:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isMovable_initialized)
		{
			flags.isMovable_initialized = YES;
			bools.cachedIsMovable = value;
		}
	}	
}

//---------------------------------------------------------- 
//  posixPermissions
//---------------------------------------------------------- 

- (BOOL)posixPermissions_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.posixPermissions_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:posixPermissions_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setPosixPermissions:(UInt32)value;
{
	@synchronized(cache32) {
		if (!flags.posixPermissions_initialized)
		{
			flags.posixPermissions_initialized = YES;
			[cache32 setInt:value atIndex:posixPermissions_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  posixFileMode
//---------------------------------------------------------- 

- (BOOL)posixFileMode_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.posixFileMode_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:posixFileMode_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setPosixFileMode:(UInt32)value;
{
	@synchronized(cache32) {
		if (!flags.posixFileMode_initialized)
		{
			flags.posixFileMode_initialized = YES;
			[cache32 setInt:value atIndex:posixFileMode_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  vRefNum
//---------------------------------------------------------- 

- (BOOL)vRefNum_initialized:(FSVolumeRefNum*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.vRefNum_initialized;
		if (result)
		{
			if (outValue)
				*outValue = (short)[cache32 intAtIndex:vRefNum_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setVRefNum:(FSVolumeRefNum)value;
{
	@synchronized(cache32) {
		if (!flags.vRefNum_initialized)
		{
			flags.vRefNum_initialized = YES;
			[cache32 setInt:value atIndex:vRefNum_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  valence
//---------------------------------------------------------- 

- (BOOL)valence_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.valence_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:valence_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setValence:(UInt32)value;
{
	@synchronized(cache32) {
		if (!flags.valence_initialized)
		{
			flags.valence_initialized = YES;
			[cache32 setInt:value atIndex:valence_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  fileSize
//---------------------------------------------------------- 

- (BOOL)fileSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache64) {
		result = flags.fileSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache64 intAtIndex:fileSize_cacheIndex64];
		}
	}
	
	return result;	
}

- (void)setFileSize:(UInt64)value;
{
	@synchronized(cache64) {
		if (!flags.fileSize_initialized)
		{
			flags.fileSize_initialized = YES;
			[cache64 setInt:value atIndex:fileSize_cacheIndex64];
		}
	}	
}

//---------------------------------------------------------- 
//  physicalFileSize
//---------------------------------------------------------- 

- (BOOL)physicalFileSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache64) {
		result = flags.physicalFileSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache64 intAtIndex:physicalFileSize_cacheIndex64];
		}
	}
	
	return result;	
}

- (void)setPhysicalFileSize:(UInt64)value;
{
	@synchronized(cache64) {
		if (!flags.physicalFileSize_initialized)
		{
			flags.physicalFileSize_initialized = YES;
			[cache64 setInt:value atIndex:physicalFileSize_cacheIndex64];
		}
	}	
}

//---------------------------------------------------------- 
//  metadata
//---------------------------------------------------------- 

- (BOOL)metadata_initialized:(NTMetadata**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.metadata_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:metadata_cacheIndex];
		}
	}
	
	return result;	
}

- (void)setMetadata:(NTMetadata*)value;
{
	@synchronized(cache) {
		if (!flags.metadata_initialized)
		{
			flags.metadata_initialized = YES;
			[cache setObj:value atIndex:metadata_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}	
}

//---------------------------------------------------------- 
//  isStickyBitSet
//---------------------------------------------------------- 

- (BOOL)isStickyBitSet_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isStickyBitSet_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsStickyBitSet;
		}
	}
	
	return result;	
}

- (void)setIsStickyBitSet:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isStickyBitSet_initialized)
		{
			flags.isStickyBitSet_initialized = YES;
			bools.cachedIsStickyBitSet = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isPipe
//---------------------------------------------------------- 

- (BOOL)isPipe_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isPipe_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsPipe;
		}
	}
	
	return result;	
}

- (void)setIsPipe:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isPipe_initialized)
		{
			flags.isPipe_initialized = YES;
			bools.cachedIsPipe = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isVolume
//---------------------------------------------------------- 

- (BOOL)isVolume_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isVolume_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsVolume;
		}
	}
	
	return result;	
}

- (void)setIsVolume:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isVolume_initialized)
		{
			flags.isVolume_initialized = YES;
			bools.cachedIsVolume = value;
		}
	}	
}

//---------------------------------------------------------- 
//  hasDirectoryContents
//---------------------------------------------------------- 

- (BOOL)hasDirectoryContents_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.hasDirectoryContents_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedHasDirectoryContents;
		}
	}
	
	return result;	
}

- (void)setHasDirectoryContents:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.hasDirectoryContents_initialized)
		{
			flags.hasDirectoryContents_initialized = YES;
			bools.cachedHasDirectoryContents = value;
		}
	}	
}

//---------------------------------------------------------- 
//  hasVisibleDirectoryContents
//---------------------------------------------------------- 

- (BOOL)hasVisibleDirectoryContents_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.hasVisibleDirectoryContents_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedHasVisibleDirectoryContents;
		}
	}
	
	return result;	
}

- (void)setHasVisibleDirectoryContents:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.hasVisibleDirectoryContents_initialized)
		{
			flags.hasVisibleDirectoryContents_initialized = YES;
			bools.cachedHasVisibleDirectoryContents = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isServerAlias
//---------------------------------------------------------- 

- (BOOL)isServerAlias_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isServerAlias_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsServerAlias;
		}
	}
	
	return result;	
}

- (void)setIsServerAlias:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isServerAlias_initialized)
		{
			flags.isServerAlias_initialized = YES;
			bools.cachedIsServerAlias = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isBrokenAlias
//---------------------------------------------------------- 

- (BOOL)isBrokenAlias_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isBrokenAlias_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsBrokenAlias;
		}
	}
	
	return result;	
}

- (void)setIsBrokenAlias:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isBrokenAlias_initialized)
		{
			flags.isBrokenAlias_initialized = YES;
			bools.cachedIsBrokenAlias = value;
		}
	}	
}

//---------------------------------------------------------- 
//  resolvedDesc 
//---------------------------------------------------------- 

- (BOOL)resolvedDesc_initialized:(NTFileDesc**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.resolvedDesc_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:resolvedDesc_cacheIndex];
		}
	}
	
	return result;
}

- (void)setResolvedDesc:(NTFileDesc*)value;
{
	@synchronized(cache) {
		if (!flags.resolvedDesc_initialized)
		{
			flags.resolvedDesc_initialized = YES;
			[cache setObj:value atIndex:resolvedDesc_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

- (BOOL)rsrcForkSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache64) {
		result = flags.rsrcForkSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache64 intAtIndex:rsrcForkSize_cacheIndex64];
		}
	}
	
	return result;	
}

- (void)setRsrcForkSize:(UInt64)value;
{
	@synchronized(cache64) {
		if (!flags.rsrcForkSize_initialized)
		{
			flags.rsrcForkSize_initialized = YES;
			[cache64 setInt:value atIndex:rsrcForkSize_cacheIndex64];
		}
	}	
}

- (BOOL)dataForkSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache64) {
		result = flags.dataForkSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache64 intAtIndex:dataForkSize_cacheIndex64];
		}
	}
	
	return result;		
}

- (void)setDataForkSize:(UInt64)value;
{
	@synchronized(cache64) {
		if (!flags.dataForkSize_initialized)
		{
			flags.dataForkSize_initialized = YES;
			[cache64 setInt:value atIndex:dataForkSize_cacheIndex64];
		}
	}	
}

- (BOOL)rsrcForkPhysicalSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache64) {
		result = flags.mRsrcForkPhysicalSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache64 intAtIndex:rsrcForkPhysicalSize_cacheIndex64];
		}
	}
	
	return result;	
}

- (void)setRsrcForkPhysicalSize:(UInt64)value;
{
	@synchronized(cache64) {
		if (!flags.mRsrcForkPhysicalSize_initialized)
		{
			flags.mRsrcForkPhysicalSize_initialized = YES;
			[cache64 setInt:value atIndex:rsrcForkPhysicalSize_cacheIndex64];
		}
	}	
}

- (BOOL)dataForkPhysicalSize_initialized:(UInt64*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache64) {
		result = flags.mDataForkPhysicalSize_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache64 intAtIndex:dataForkPhysicalSize_cacheIndex64];
		}
	}
	
	return result;		
}

- (void)setDataForkPhysicalSize:(UInt64)value;
{
	@synchronized(cache64) {
		if (!flags.mDataForkPhysicalSize_initialized)
		{
			flags.mDataForkPhysicalSize_initialized = YES;
			[cache64 setInt:value atIndex:dataForkPhysicalSize_cacheIndex64];
		}
	}	
}

//---------------------------------------------------------- 
//  type
//---------------------------------------------------------- 

- (BOOL)type_initialized:(OSType*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.type_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:type_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setType:(OSType)value;
{
	@synchronized(cache32) {
		if (!flags.type_initialized)
		{
			flags.type_initialized = YES;
			[cache32 setInt:value atIndex:type_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  creator
//---------------------------------------------------------- 

- (BOOL)creator_initialized:(OSType*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.creator_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:creator_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setCreator:(OSType)value;
{
	@synchronized(cache32) {
		if (!flags.creator_initialized)
		{
			flags.creator_initialized = YES;
			[cache32 setInt:value atIndex:creator_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  label
//---------------------------------------------------------- 

- (BOOL)label_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.label_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:label_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setLabel:(UInt32)value;
{
	@synchronized(cache32) {
		if (!flags.label_initialized)
		{
			flags.label_initialized = YES;
			[cache32 setInt:value atIndex:label_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  groupID
//---------------------------------------------------------- 

- (BOOL)groupID_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.groupID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:groupID_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setGroupID:(UInt32)value;
{
	@synchronized(cache32) {
		if (!flags.groupID_initialized)
		{
			flags.groupID_initialized = YES;
			[cache32 setInt:value atIndex:groupID_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  ownerID
//---------------------------------------------------------- 

- (BOOL)ownerID_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.ownerID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:ownerID_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setOwnerID:(UInt32)value;
{
	@synchronized(cache32) {
		if (!flags.ownerID_initialized)
		{
			flags.ownerID_initialized = YES;
			[cache32 setInt:value atIndex:ownerID_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  nodeID
//---------------------------------------------------------- 

- (BOOL)nodeID_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.nodeID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:nodeID_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setNodeID:(UInt32)value;
{
	@synchronized(cache32) {
		if (!flags.nodeID_initialized)
		{
			flags.nodeID_initialized = YES;
			[cache32 setInt:value atIndex:nodeID_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  parentDirID
//---------------------------------------------------------- 

- (BOOL)parentDirID_initialized:(UInt32*)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache32) {
		result = flags.parentDirID_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache32 intAtIndex:parentDirID_cacheIndex32];
		}
	}
	
	return result;	
}

- (void)setParentDirID:(UInt32)value;
{
	@synchronized(cache32) {
		if (!flags.parentDirID_initialized)
		{
			flags.parentDirID_initialized = YES;
			[cache32 setInt:value atIndex:parentDirID_cacheIndex32];
		}
	}	
}

//---------------------------------------------------------- 
//  isParentAVolume
//---------------------------------------------------------- 

- (BOOL)isParentAVolume_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isParentAVolume_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsParentAVolume;
		}
	}
	
	return result;	
}

- (void)setIsParentAVolume:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isParentAVolume_initialized)
		{
			flags.isParentAVolume_initialized = YES;
			bools.cachedIsParentAVolume = value;
		}
	}	
}

//---------------------------------------------------------- 
//  isNameLocked
//---------------------------------------------------------- 

- (BOOL)isNameLocked_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.isNameLocked_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedIsNameLocked;
		}
	}
	
	return result;	
}

- (void)setIsNameLocked:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.isNameLocked_initialized)
		{
			flags.isNameLocked_initialized = YES;
			bools.cachedIsNameLocked = value;
		}
	}	
}

//---------------------------------------------------------- 
//  originalAliasFilePath 
//---------------------------------------------------------- 

- (BOOL)originalAliasFilePath_initialized:(NSString**)outValue;
{
	BOOL result=NO;
	
	@synchronized(cache) {
		result = flags.originalAliasFilePath_initialized;
		if (result)
		{
			if (outValue)
				*outValue = [cache objAtIndex:originalAliasFilePath_cacheIndex];
		}
	}
	
	return result;
}

- (void)setOriginalAliasFilePath:(NSString*)value;
{
	@synchronized(cache) {
		if (!flags.originalAliasFilePath_initialized)
		{
			flags.originalAliasFilePath_initialized = YES;
			[cache setObj:value atIndex:originalAliasFilePath_cacheIndex];
		}
		else
		{
			// the caller might assume that this value will be retained by this call, but we are not storing it.
			// so be safe and retain and autorelease it
			[[value retain] autorelease];
		}
	}
}

//---------------------------------------------------------- 
//  hasBeenModified
//---------------------------------------------------------- 

- (BOOL)hasBeenModified_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.hasBeenModified_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedHasBeenModified;
		}
	}
	
	return result;	
}

- (void)setHasBeenModified:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.hasBeenModified_initialized)
		{
			flags.hasBeenModified_initialized = YES;
			bools.cachedHasBeenModified = value;
		}
	}	
}

//---------------------------------------------------------- 
//  hasBeenRenamed
//---------------------------------------------------------- 

- (BOOL)hasBeenRenamed_initialized:(BOOL*)outValue;
{
	BOOL result=NO;
	
	@synchronized(self) {
		result = flags.hasBeenRenamed_initialized;
		if (result)
		{
			if (outValue)
				*outValue = bools.cachedHasBeenRenamed;
		}
	}
	
	return result;	
}

- (void)setHasBeenRenamed:(BOOL)value;
{
	@synchronized(self) {
		if (!flags.hasBeenRenamed_initialized)
		{
			flags.hasBeenRenamed_initialized = YES;
			bools.cachedHasBeenRenamed = value;
		}
	}	
}

@end
