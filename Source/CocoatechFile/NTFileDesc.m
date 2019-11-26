//
//  NTFileDesc.m
//  CocoatechFile
//
//  Created by sgehrman on Sun Jul 15 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTFileDesc.h"
#import <sys/stat.h>
#import "NTAliasFileManager.h"
#import "NTVolume.h"
#import "NTFileTypeIdentifier.h"
#import "NTIcon.h"
#import "NTIconStore.h"
#import "NTFSRefObject.h"
#import "NTFileDescMemCache.h"
#import "NTStringShare.h"
#import "NTAlias.h"
#import "NTFileDesc-NTUtilities.h"
#import "NTFileDesc-Private.h"
#import "NTVolumeCache.h"
#import "NTVolumeNotificationMgr.h"
#import "NTMetadata.h"
#import "NTFileDescData.h"
#import "NTCGImage.h"
#import <sys/paths.h>
#import "NTVolumeMgrState.h"
#include <sys/xattr.h>

@implementation NTFileDesc

@synthesize FSRefObject;
@synthesize volumeMgrState;

+ (void)initialize;
{
	NTINITIALIZE;
	
	// initialize some singletons
	[self bootVolumeDesc];
}

- (void)updateFSRefObject:(NTFSRefObject*)refObject;
{
    mv_valid = NO;
	
	// a nil refObject means it's the computer
    if (refObject)
	{
		[self setFSRefObject:refObject];
        mv_valid = [[self FSRefObject] isValid];
	}
	else
    {
        mv_isComputer = YES;
		mv_valid = YES;
		
		[self setVolumeMgrState:[NTVolumeMgrState state]];
    }
	
	cachedData = [[NTFileDescData alloc] init];  // [NTFileDescData cache] avoiding autorelease hit
}

- (id)initWithFSRefObject:(NTFSRefObject*)refObject;
{
    self = [super init];
	
    [self updateFSRefObject:refObject];
	
    return self;
}

- (id)initWithPath:(NSString *)path;
{	
    self = [super init];
	
	// nil path is invalid, computer is @""
	if (path)
	{
		NTFSRefObject* refObject=nil;
		if ([path length])
			refObject = [NTFSRefObject refObjectWithPath:path resolvePath:NO];
		
		// if nil, path was zero length (computer)
		[self updateFSRefObject:refObject];
	}
	else
		mv_valid = NO;
	
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    if ([aCoder allowsKeyedCoding])
	{
		NSString* path = [self path];
		
		if (path)
			[aCoder encodeObject:path forKey:@"path"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    NSString* path=nil;
	
    if ([aDecoder allowsKeyedCoding])
        path = [aDecoder decodeObjectForKey:@"path"];
	
    if (path)
    {
        self = [self initWithPath:path];
		
        return self;
    }
    
    return nil;
}

- (void)dealloc;
{	
	[cachedData release];
    cachedData = nil;
	
    self.FSRefObject = nil;
    self.volumeMgrState = nil;
	
    [super dealloc];
}

- (NTFileDesc*)descResolveIfAlias;
{
    return [self descResolveIfAlias:NO];
}

- (NTFileDesc*)descResolveIfAlias:(BOOL)resolveIfServerAlias;
{	
    if ([self isAlias])
	{
		NTFileDesc* resolved = [self resolvedDesc:resolveIfServerAlias];
		
		// could be a server alias that returns nil, or an alias that can't be resolved
		if (resolved) 
			return [[resolved retain] autorelease];
	}
	
    return self;
}

- (NTFileDesc*)aliasDesc; // if we were resolved from an alias, this is the original alias file
{
	if (!mv_valid || mv_isComputer)
        return nil;

	// we store only the path in the cache, this was to avoid a double retain
	// a desc retains it's resolved alias, so the resolved desc can't retain the aliasDesc
	// only used in one part of the code for now, so performance is not necessary
	
	NSString* path=nil;
	[cachedData originalAliasFilePath_initialized:&path]; // set in the object internally
		
	if (path)
		return [NTFileDesc descNoResolve:path]; 
	
    return nil;
}

// creates a new copy of the desc (resets mod dates, displayname etc)
- (NTFileDesc*)freshDesc;  
{
    NTFileDesc* result;
    
    if ([self isComputer])
        result = [NTFileDesc descNoResolve:@""];
    else
    {
        result = [NTFileDesc descFSRef:[self FSRefPtr]];
        
        // remember originalAliasFilePath if exists
        [result setAliasDesc:[self aliasDesc]];
    }
    
    return result;
}

// is the directory or file open
- (BOOL)isOpen;
{
	BOOL result = NO;
	@synchronized(self) {
		result = [[self FSRefObject] isOpen];
	}
	
	return result;
}

- (NSString*)longDescription;
{
    NSMutableString* result = [NSMutableString stringWithString:[self description]];
	
    [result appendString:@"\n"];
	
	BOOL isOwner = ([[NTUsersAndGroups sharedInstance] userID] == [self ownerID]);
	BOOL isGroup = ([[NTUsersAndGroups sharedInstance] groupID] == [self groupID]);
	BOOL isMemberOfGroup = [[NTUsersAndGroups sharedInstance] userIsMemberOfGroup:[self groupID]];
	
    [result appendString:[NSString stringWithFormat:@"isOwner: %@\n", isOwner?@"YES":@"NO"]];
    [result appendString:[NSString stringWithFormat:@"isGroup: %@\n", isGroup?@"YES":@"NO"]];
    [result appendString:[NSString stringWithFormat:@"isMemberOfGroup: %@\n", isMemberOfGroup?@"YES":@"NO"]];
	
    [result appendString:[[self FSRefObject] description]];
	
    return result;
}

- (NSString*)description;
{
    NSMutableString* result = [NSMutableString stringWithString:@"path:"];
	
	if ([self path])
		[result appendString:[self path]];
	else
		[result appendString:@"<path nil>"];

	[result appendString:@"\n"];
	
	if ([self label])
	{
		[result appendString:[NSString stringWithFormat:@"label: %d", [self label]]];
		[result appendString:@"\n"];
	}
	
    [result appendString:@"valid:"];
    if ([self isValid])
        [result appendString:@"YES"];
    else
        [result appendString:@"NO"];
    [result appendString:@"\n"];
	
    [result appendString:@"volume:"];
    if ([self isVolume])
        [result appendString:@"YES"];
    else
        [result appendString:@"NO"];
	
    if ([self resolvedDesc:NO])
    {
        [result appendString:@"\n"];
        [result appendString:@"resolves to:"];
		
		if ([[self resolvedDesc:NO] path])
			[result appendString:[[self resolvedDesc:NO] path]];
		
        [result appendString:@"\n"];
        [result appendString:@"valid:"];
        if ([[self resolvedDesc:NO] isValid])
            [result appendString:@"YES"];
        else
            [result appendString:@"NO"];
    }
	
    return result;
}

- (BOOL)isComputer
{
    if (!mv_valid)
        return NO;
	
    return mv_isComputer;
}

- (BOOL)isValid
{
    return mv_valid;
}

// could be a path on a disk that was just unmounted.
// double check the file is there
- (BOOL)stillExists;
{
	if (!mv_valid)
		return NO;
	
	if (mv_isComputer)
		return YES;  // computer levels always valid
	
	BOOL result = NO;
	@synchronized(self) {
		result = [[self FSRefObject] stillExists];
	}
	
	return result;
}

- (UInt32)nodeID;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![cachedData nodeID_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] nodeID];
		
			[cachedData setNodeID:result];
		}
    }
	
    return result;
}

- (FSVolumeRefNum)volumeRefNum;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	FSVolumeRefNum result=0;
	if (![cachedData vRefNum_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] volumeRefNum];
			
			[cachedData setVRefNum:result];
        }
    }
	
    return result;
}

- (NTMetadata*)metadata;
{
	if (!mv_valid || mv_isComputer)
        return nil;

	NTMetadata* result=nil;
	if (![cachedData metadata_initialized:&result])
	{
		@synchronized(self) {
			result = [NTMetadata metadata:[self path]];
			
			[cachedData setMetadata:result];
		}
	}
	
	return result;
}

- (NSArray*)FSRefPath:(BOOL)includeSelf;
{
    NSMutableArray* result;
    NTFSRefObject* parent;
	
    // build a path of FSRefs /FSRef/FSRef/FSRef, the order of the array starts with the file and goes until it reaches the volume
    result = [NSMutableArray arrayWithCapacity:6];
	
	@synchronized(self) {
		parent = [self FSRefObject];
		
		if (includeSelf)
			[result addObject:parent];
		
		while (parent)
		{
			parent = [parent parentFSRef];
			
			if (parent)
				[result addObject:parent];
		}
	}
	
    return result;
}

- (BOOL)isParentOfRefPath:(NSArray*)refPath;
{
	if (!mv_valid)
        return NO;
	
	if (mv_isComputer)
		return YES;
	
	BOOL result = NO;
	if ([self isDirectory])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isParentOfRefPath:refPath];
		}
	}
	
	return result;	
}

- (BOOL)isParentOfFSRef:(FSRef*)fsRefPtr;  // used to determine if FSRef is contained by this directory
{
	if (!mv_valid)
        return NO;
	
	if (mv_isComputer)
		return YES;
	
	BOOL result = NO;
	if ([self isDirectory])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isParentOfFSRef:fsRefPtr];
		}
	}
	
	return result;
}

- (BOOL)isParentOfDesc:(NTFileDesc*)desc;  // used to determine if NTFileDesc is contained by this directory
{
	BOOL result = NO;
	
	// same volume?
	if ([self volumeRefNum] == [desc volumeRefNum])
		result = [self isParentOfFSRef:[desc FSRefPtr]];
	
	return result;
}

// if  nil is returned, there is no parent
// not cached since it could become invalid if parent renamed
- (NTFileDesc *)parentDesc;
{
	if (!mv_valid || mv_isComputer)
        return nil;
	
	NTFileDesc* result=nil;
	
	@synchronized(self) {
		if (![self isVolume])  // old code returned nil for volumes, url code returns /Volumes
		{
			NSURL* parentURL = [self resourceForKey:NSURLParentDirectoryURLKey];
			NSString* thePath = [parentURL path];
			
			if ([thePath length])
				result = [NTFileDesc descNoResolve:thePath];
		}
	}			
	
    return result;
}

- (UInt32)parentDirID;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![cachedData parentDirID_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] parentDirID];
			
			[cachedData setParentDirID:result];
		}
    }
	
    return result;
}

- (BOOL)parentIsVolume;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isParentAVolume_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] parentIsVolume];
		
			[cachedData setIsParentAVolume:result];
		}
    }
	
    return result;
}

// forDisplay will give you "" when asking for the parent of a volume instead of /Volumes
- (NSString *)parentPath:(BOOL)forDisplay;
{
    NSString* result;
	
    if (!mv_valid)
        return @"";
	
    result = [[self path] stringByDeletingLastPathComponent];
    if (!result)
        return @"";
	
    // we don't want the parent of /Volumes/disk1 to be /Volumes, just take them back to @""
    if (forDisplay)
    {
        if ([result isEqualToString:@"/Volumes"])
            return @"";
    }
	
    if ([result isEqualToString:[self path]])
        return @"";
	
    return result;
}

- (NTFileDesc *)application;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NTFileDesc* result=nil;
	if (![cachedData application_initialized:&result])
	{
		@synchronized(self) {
			if ([self FSRefPtr])
			{
				OSStatus err;
				FSRef outAppRef;
				
				err = LSGetApplicationForItem([self FSRefPtr], kLSRolesAll, &outAppRef, NULL);
				if (err == noErr)
					result = [NTFileDesc descFSRef:&outAppRef];					
			}
			
			[cachedData setApplication:result];
		}
    }
	
    return result;
}

- (BOOL)applicationCanOpenFile:(NTFileDesc*)droppedFile;
{
    BOOL result=NO;
	
    if (!mv_valid || mv_isComputer)
        return NO;
	
    if ([self isApplication])
    {
        Boolean outAcceptsItem;
        OSStatus err;
		NSURL* droppedURL = [droppedFile URL];
		NSURL* theURL = [self URL];
		
        if (droppedURL && theURL)
        {
			err = LSCanURLAcceptURL((CFURLRef)droppedURL, 
									(CFURLRef)theURL, 
									kLSRolesAll,
									kLSAcceptDefault, &outAcceptsItem);
			
            if (err == noErr)
                result = outAcceptsItem;
        }
    }
	
    return result;
}

- (NSString *)name;
{
    if (!mv_valid || mv_isComputer)
        return @"";
    
	NSString *result=nil;
	@synchronized(self) {
		// NOTE: NSURLNameKey returns the hard disk name for "/", so catch that here 
		if (FSCompareFSRefs([NTFSRefObject bootFSRef], [self FSRefPtr]) == noErr) 
			result = @"/"; 
		else 
			result = [self resourceForKey:NSURLNameKey];
	}
	
    return result;
}

- (NSString *)path;
{
	if (!mv_valid)
		return nil;
	
	if (mv_isComputer)
		return @"";
		
	NSString* result=nil;
	@synchronized(self) {
		result = [[self FSRefObject] path];
	}
    
    return result;
}

- (NTFileTypeIdentifier*)typeIdentifier;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NTFileTypeIdentifier* result=nil;
	if (![cachedData typeIdentifier_initialized:&result])
	{
		@synchronized(self) {
			result = [NTFileTypeIdentifier typeIdentifier:self];
			
			[cachedData setTypeIdentifier:result];
		}
    }
	
    return result;
}

- (NSString *)extension;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData extension_initialized:&result])
	{
		@synchronized(self) {
			result = [[self nameWhenCreated] strictPathExtension];
			result = [[NTStringShare sharedInstance] sharedExtensionString:result];
			
			[cachedData setExtension:result];
		}
    }
	
    return result;
}

- (BOOL)isFile;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isFile_initialized:&result])
	{
		@synchronized(self) {
			if (NO)  // too slow
			{
				NSNumber* numResult = [self resourceForKey:NSURLIsRegularFileKey];
				if (numResult)
					result = [numResult boolValue];
			}
			else
				result = [[self FSRefObject] isFile];
			
			[cachedData setIsFile:result];
		}
	}
	
	return result;
}

- (BOOL)isDirectory;
{
    if (!mv_valid)
        return NO;
    else if (mv_isComputer)
        return YES;
	
    return ![self isFile];
}

- (BOOL)isOnBootVolume;
{
	return ([self volumeRefNum] == [[NTFileDesc bootVolumeDesc] volumeRefNum]);
}

- (BOOL)isNameLocked;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isNameLocked_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isNameLocked];
			
			[cachedData setIsNameLocked:result];
		}
    }
	
    return result;
}

- (BOOL)isLocked;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isLocked_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isLocked];
			
			[cachedData setIsLocked:result];
        }
    }
	
    return result;
}

- (NSString*)dictionaryKey;
{
    if (!mv_valid)
        return @"";
	
	// return computer for computer level
	if (mv_isComputer)
		return @"Computer";
	
	NSString* result=nil;
	if (![cachedData dictionaryKey_initialized:&result])
	{
		@synchronized(self) {
			// I was using the parentDirID, but this would fail in some cases where the file was moved to a different directory and the FSRef was still the same
			// don't use name in the key, the name could change and might break some code
			result = [NSString stringWithFormat:@"%d:%d", [self nodeID], [self volumeRefNum]];
			
			[cachedData setDictionaryKey:result];
		}
	}
	
    return result;
}

// like dictionaryKey, but adds the parentDirID so you can know if the item moved for example
- (NSString*)strictDictionaryKey;
{
	if (!mv_valid)
        return @"";
	
	// return computer for computer level
	if (mv_isComputer)
		return @"Computer";
	
	NSString* result=nil;
	if (![cachedData strictDictionaryKey_initialized:&result])
	{
		@synchronized(self) {
			result = [NSString stringWithFormat:@"%d:%d:%d", [self nodeID], [self volumeRefNum], [self parentDirID]];
			
			[cachedData setStrictDictionaryKey:result];
		}
	}
	
    return result;	
}

- (BOOL)hasCustomIcon;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData hasCustomIcon_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] hasCustomIcon];
			
			[cachedData setHasCustomIcon:result];
        }
    }
	
    return result;
}

- (BOOL)isStationery;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isStationery_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isStationery];
			
			[cachedData setIsStationery:result];
        }
    }
	
    return result;
}

- (BOOL)isBundleBitSet
{
    if (!mv_valid || mv_isComputer)
        return NO;
    
	BOOL result=NO;
	if (![cachedData isBundleBitSet_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isBundleBitSet];
			
			[cachedData setIsBundleBitSet:result];
        }
    }
    
    return result;    
}

- (NSString*)bundleSignature;
{
	if (!mv_valid)
        return @"";
	
	NSString* result=nil;
	if (![cachedData bundleSignature_initialized:&result])
	{
		@synchronized(self) {
			if ([self isPackage]) 
			{
				NSBundle* bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle) 
					result = [[bundle infoDictionary] stringForKey:@"CFBundleSignature"];
			}
			
			if (!result)
				result = @"";
			
			[cachedData setBundleSignature:result];
		}
	}
	
	return result;
}

- (NSString*)bundleIdentifier;
{
	if (!mv_valid)
        return @"";
	
	NSString* result=nil;
	if (![cachedData bundleIdentifier_initialized:&result])
	{
		@synchronized(self) {
			if ([self isPackage]) 
			{
				NSBundle* bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle) 
					result = [bundle bundleIdentifier];
			}
			
			if (!result)
				result = @"";
			
			[cachedData setBundleIdentifier:result];
		}
	}
	
	return result;
}

- (BOOL)isAliasBitSet;
{
    if (!mv_valid || mv_isComputer)
        return NO;
    
	BOOL result=NO;
	if (![cachedData isAliasBitSet_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] isAliasBitSet];
			
			[cachedData setIsAliasBitSet:result];
        }
    }
    
    return result;    
}

- (NSString*)executablePath;
{
    NSString* result = nil;

	// frameworks, plugins, apps, not all are packages, so removed check
	if ([self isDirectory])
	{
		NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
		if (bundle)
			result = [bundle executablePath];
	}
	
	return result;
}

// read only even if we had admin privleges
- (BOOL)isReadOnly;
{
	if (!mv_valid || mv_isComputer)
        return YES;

	BOOL result=NO;
	if (![cachedData isReadOnly_initialized:&result])
	{
		@synchronized(self) {
			if ([self isLocked] || [[self volume] isReadOnly])
				result = YES;
			
			[cachedData setIsReadOnly:result];
        }
    }
	
    return result;
}

- (BOOL)isAlias;
{
    return ([self isSymbolicLink] || [self isCarbonAlias] || [self isPathFinderAlias]);
}

- (BOOL)isCarbonAlias;
{
    if (!mv_valid || mv_isComputer)
        return NO;
    
	BOOL result=NO;
	if (![cachedData isCarbonAlias_initialized:&result])
	{
		@synchronized(self) {
			if ([self isFile])
			{
				result = [[self FSRefObject] isCarbonAlias];
				
				// NOTE: this shit doesn't work for the /Volumes synthetic mount point aliases
				//	NSNumber* numResult = [self resourceForKey:NSURLIsAliasFileKey];
				//	if (numResult)
				//		result = [numResult boolValue];
				//	
				//	// not sure when Apple added this, but the alias bit is set for sym links also, let's check for that and return NO
				//	// we only return yet for classic carbon aliases
				//	if (result && [self isSymbolicLink])
				//		result = NO;
			}
			
			[cachedData setIsCarbonAlias:result];
        }
    }
    
    return result;
}

- (BOOL)isPathFinderAlias;
{
    if (!mv_valid || mv_isComputer)
        return NO;
    
	BOOL result=NO;
	if (![cachedData isPathFinderAlias_initialized:&result])
	{
		@synchronized(self) {
			result = [[self extension] isEqualToStringCaseInsensitive:kPathFinderAliasExtension];
			
			[cachedData setIsPathFinderAlias:result];
        }
    }
    
    return result;
}

- (BOOL)isSymbolicLink;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isSymbolicLink_initialized:&result])
	{
		@synchronized(self) {
			if (NO)  // too slow
			{
				NSNumber* numResult = [self resourceForKey:NSURLIsSymbolicLinkKey];
				if (numResult)
					result = [numResult boolValue];
			}
			else
				result = [[self FSRefObject] isSymbolicLink];
			
			[cachedData setIsSymbolicLink:result];
        }
    }
	
    return result;
}

- (BOOL)isStickyBitSet;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isStickyBitSet_initialized:&result])
	{
		@synchronized(self) {
			result = ((S_ISVTX & [[self FSRefObject] modeBits]) != 0);
			
			[cachedData setIsStickyBitSet:result];
        }
    }
	
    return result;
}

- (BOOL)isPipe;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isPipe_initialized:&result])
	{
		@synchronized(self) {
			result = ((S_IFIFO & [[self FSRefObject] modeBits]) != 0);
			
			[cachedData setIsPipe:result];
        }
    }
	
    return result;
}

- (BOOL)isVolume;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isVolume_initialized:&result])
	{
		@synchronized(self) {
			// this was slower for size calculator
			if (NO)
			{
				if ([self isDirectory])
				{
					NSNumber* numResult = [self resourceForKey:NSURLIsVolumeKey];
					if (numResult)
						result = [numResult boolValue];
				}
			}
			else
				result = [[self FSRefObject] isVolume];

			[cachedData setIsVolume:result];
        }
    }
	
    return result;
}

- (UInt32)label;
{
	if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![cachedData label_initialized:&result])
	{
		@synchronized(self) {
			NSNumber* numResult = [self resourceForKey:NSURLLabelNumberKey];
			if (numResult)
				result = [numResult unsignedIntValue];
			
			[cachedData setLabel:result];
		}
    }
	
    return result;
}

- (OSType)type;
{
	if (!mv_valid || mv_isComputer)
        return 0;
	
	OSType result=0;
	if (![cachedData type_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] fileType];
			
			[cachedData setType:result];
		}
    }
	
    return result;
}

- (OSType)creator;
{
	if (!mv_valid || mv_isComputer)
        return 0;
	
	OSType result=0;
	if (![cachedData creator_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] fileCreator];
			
			[cachedData setCreator:result];
		}
    }
	
    return result;
}

- (UInt64)rsrcForkSize;
{    
	if (!mv_valid || mv_isComputer || ![self isFile])
		return 0;
	
    UInt64 result=0;
	if (![cachedData rsrcForkSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[cachedData rsrcForkSize_initialized:&result];
    }
    
    return result;
}

- (UInt64)dataForkSize;
{
	if (!mv_valid || mv_isComputer || ![self isFile])
		return 0;
	
    UInt64 result=0;
	if (![cachedData dataForkSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[cachedData dataForkSize_initialized:&result];
    }
    
    return result;
}

- (UInt64)rsrcForkPhysicalSize;
{    
	if (!mv_valid || mv_isComputer || ![self isFile])
		return 0;
	
    UInt64 result=0;
	if (![cachedData rsrcForkPhysicalSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[cachedData rsrcForkPhysicalSize_initialized:&result];
    }
    
    return result;
}

- (UInt64)dataForkPhysicalSize;
{
	if (!mv_valid || mv_isComputer || ![self isFile])
		return 0;
	
    UInt64 result=0;
	if (![cachedData dataForkPhysicalSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[cachedData dataForkPhysicalSize_initialized:&result];
    }
    
    return result;
}

// total size of all forks or folder size if set
- (UInt64)size;
{
	if (!mv_valid || mv_isComputer || ![self isFile])
        return 0;
	
	UInt64 result=0;
	if (![cachedData fileSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[cachedData fileSize_initialized:&result];
	}
	
    return result;
}

// total size of all forks or folder size if set
- (UInt64)physicalSize;
{
	if (!mv_valid || mv_isComputer || ![self isFile])
        return 0;
	
	UInt64 result=0;
	if (![cachedData physicalFileSize_initialized:&result])
	{
		@synchronized(self) {
			[self initializeSizeInfo];
		}
		
		// get the result
		[cachedData physicalFileSize_initialized:&result];
	}
	
    return result;
}

- (UInt32)valence;  // only valid for folders, 0 if file or invalid
{
    if (!mv_valid || mv_isComputer || [self isFile])
        return 0;
    
	UInt32 result=0;
	if (![cachedData valence_initialized:&result])
	{
		@synchronized(self) {			
			// don't call unless a native HFS disk
			if ([[self volume] isHFS])
				result = [[self FSRefObject] valence];
			
			[cachedData setValence:result];
		}
	}
	
    return result;
}

- (UInt32)posixPermissions;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![cachedData posixPermissions_initialized:&result])
	{
		@synchronized(self) {
			result = ([[self FSRefObject] modeBits] & ACCESSPERMS);
		
			[cachedData setPosixPermissions:result];
		}
    }
	
    return result;
}

- (UInt32)posixFileMode;
{
    if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![cachedData posixFileMode_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] modeBits];
		
			[cachedData setPosixFileMode:result];
		}
    }
	
    return result;
}

- (BOOL)isExecutableBitSet;
{
	UInt32 perm = [self posixPermissions];
	
    if ( ((perm & S_IXUSR) == S_IXUSR) ||
		 ((perm & S_IXGRP) == S_IXGRP) ||
		 ((perm & S_IXOTH) == S_IXOTH) )
        return YES;
    
    return NO;
}

- (NSString*)permissionString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData permissionString_initialized:&result])
	{
		@synchronized(self) {
			result = [NTFileDesc permissionsTextForDesc:self includeOctal:YES];
			
			[cachedData setPermissionString:result];
		}
    }
	
    return result;
}

- (UInt32)ownerID;
{
	if (!mv_valid || mv_isComputer)
        return 0;
	
	UInt32 result=0;
	if (![cachedData ownerID_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] ownerID];
			
			[cachedData setOwnerID:result];
		}
    }
	
    return result;
}

- (NSString *)ownerName;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData ownerName_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] ownerName];
			
			[cachedData setOwnerName:result];
		}
    }
	
    return result;
}

- (UInt32)groupID;
{
	if (!mv_valid || mv_isComputer)
        return 0;

	UInt32 result=0;
	if (![cachedData groupID_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] groupID];
			
			[cachedData setGroupID:result];
		}
    }
	
    return result;
}

- (NSString *)groupName;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData groupName_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] groupName];
			
			[cachedData setGroupName:result];
		}
    }
	
    return result;
}

- (NSDate*)modificationDate
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![cachedData modificationDate_initialized:&result])
	{
		@synchronized(self) {
			result = [self resourceForKey:NSURLContentModificationDateKey];
			
			[cachedData setModificationDate:result];
		}
	}
	
	return result;
}

- (NSDate*)creationDate
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![cachedData creationDate_initialized:&result])
	{
		@synchronized(self) {
			result = [self resourceForKey:NSURLCreationDateKey];
			
			[cachedData setCreationDate:result];
		}
	}
	
    return result;
}

// time of last file status change, rename, permissions etc
- (NSDate*)attributeModificationDate;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![cachedData attributeDate_initialized:&result])
	{
		@synchronized(self) {
			result = [self resourceForKey:NSURLAttributeModificationDateKey];
			
			[cachedData setAttributeDate:result];
		}
	}
	
    return result;
}

- (NSDate*)accessDate;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![cachedData accessDate_initialized:&result])
	{
		@synchronized(self) {
			result = [self resourceForKey:NSURLContentAccessDateKey];
			
			[cachedData setAccessDate:result];
		}
	}
	
    return result;
}

- (BOOL)hasBeenModified; // networkVolume = NO;
{
	return [self hasBeenModified:NO];
}

// networkVolume's don't always update their finderFlags like label
- (BOOL)hasBeenModified:(BOOL)networkVolume;
{
    if (!mv_valid)
        return NO;
    
	BOOL result=NO;
	[cachedData hasBeenModified_initialized:&result];
	
	// once it's been modifed, don't check again, but check if still == 0
	if (!result)
	{
		@synchronized(self) {
			if (mv_isComputer)
			{
				// if the computer level, check the number of mounted volume to see if it has changed
				if ([[self volumeMgrState] changed])
					result = YES;
			}
			else
				result = [[self FSRefObject] hasBeenModified:networkVolume];
			
			[cachedData setHasBeenModified:result];
		}
	}
	
    return result;
}

- (BOOL)hasBeenRenamed;
{
    if (!mv_valid)
        return NO;
    
	BOOL result=NO;
	[cachedData hasBeenRenamed_initialized:&result];
	
	// once it's been renamed, don't check again, but check if still == 0
	if (!result)
	{
		@synchronized(self) {
			result = [[self FSRefObject] hasBeenRenamed];
			
			[cachedData setHasBeenRenamed:result];
		}
	}
	
    return result;
}

- (NSString*)nameWhenCreated;
{
	if (!mv_valid)
        return @"";
	
	NSString *result;
	@synchronized(self) {
		result = [[self FSRefObject] nameWhenCreated];  // string doesn't change, so no need to worry about thread safety issues
	}
	
	return result;
}

- (const FileInfo*)fileInfo;
{
    if (!mv_valid || mv_isComputer)
        return nil;
    
    return [[self FSRefObject] fileInfo];
}

// slow, not cached
- (NSURL*)URL;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSURL* result=nil;
	@synchronized(self) {
		result = [[self FSRefObject] URL];
	}
	
    return result;
}

- (NSString*)comments;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData comments_initialized:&result])
	{
		@synchronized(self) {
			char attrdatabuf[4*1024];
			
			ssize_t attributeSize = getxattr([self fileSystemPath], "com.apple.metadata:kMDItemFinderComment", attrdatabuf, sizeof(attrdatabuf), 0, XATTR_NOFOLLOW);
			if (attributeSize < 0)
			{
				// could be attribute not found, so don't log errors
				// NSLog(@"getxattr returned: %ld (%s)", attributeSize, strerror(errno));
			}
			else if (attributeSize > 0) // don't bother if 0
			{				
				NSData* attributeData = [NSData dataWithBytes:attrdatabuf length:attributeSize];
				
				NSPropertyListFormat format;
				NSError* error=nil;
				id propList = [NSPropertyListSerialization propertyListWithData:attributeData options:0 format:&format error:&error];
				
				if ([propList isKindOfClass:[NSString class]])
					result = propList;
			}
						
			
			// this isn't always 100% in sync with what's on disk if you just set the comments it takes a second for this to update
			// this also this get's older comments that are not stored in teh xattr
			if (!result)
				result = [[self metadata] valueForAttribute:(NSString*)kMDItemFinderComment];			

			if (!result)
				result = @"";
			
			[cachedData setComments:result];
		}
	}
	
	return result;
}

- (NSDate*)lastUsedDate;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NSDate* result=nil;
	if (![cachedData lastUsedDate_initialized:&result])
	{
		@synchronized(self) {
			result = [[self metadata] valueForAttribute:(NSString*)kMDItemLastUsedDate];
						
			if (result)
				[cachedData setLastUsedDate:result];
		}
	}
		
	return result;
}

- (NSPoint)finderPosition;
{
    if (!mv_valid || mv_isComputer)
        return NSZeroPoint;
	
    NSPoint result=NSZeroPoint;
	@synchronized(self) {
		result = [[self FSRefObject] finderPosition];
	}
	
	return result;
}

- (NSString*)versionString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData version_initialized:&result])
	{
		@synchronized(self) {			
			// localizedInfoDictionary was crashing on volumes, so I added the package test
			if ([self isPackage])
			{
				NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle)
				{
					NSDictionary *dict;
					
					dict = [bundle localizedInfoDictionary];
					if (dict)
						result = [dict objectForKey:@"CFBundleShortVersionString"];
					
					if (!result)
					{
						dict = [bundle infoDictionary];
						if (dict)
							result = [dict objectForKey:@"CFBundleShortVersionString"];
					}
				}
			}
			
			// we didn't find a version, is this a carbon or classic app?
			if (!result && [self isFile])
				result = [self carbonVersionString:YES];
			
			if (!result)
				result = @"";
			
			[cachedData setVersion:result];
		}
    }
	
    return result;
}

- (NSString*)bundleVersionString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData bundleVersion_initialized:&result])
	{
		@synchronized(self) {			
			// localizedInfoDictionary was crashing on volumes, so I added the package test
			if ([self isPackage])
			{
				NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle)
				{
					NSDictionary *dict;
					
					dict = [bundle localizedInfoDictionary];
					if (dict)
						result = [dict objectForKey:@"CFBundleVersion"];
					
					if (!result)
					{
						dict = [bundle infoDictionary];
						if (dict)
							result = [dict objectForKey:@"CFBundleVersion"];
					}
				}
			}
			
			if (!result)
				result = @"";
				
			[cachedData setBundleVersion:result];
		}
    }
	
    return result;
}

- (NSString*)infoString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData getInfo_initialized:&result])
	{
		@synchronized(self) {			
			// localizedInfoDictionary was crashing on volumes, so I added the package test
			if ([self isPackage])
			{
				NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
				if (bundle)
				{
					NSDictionary *dict;
					
					dict = [bundle localizedInfoDictionary];
					if (dict)
						result = [dict objectForKey:@"CFBundleGetInfoString"];
					
					if (!result)
					{
						dict = [bundle infoDictionary];
						if (dict)
							result = [dict objectForKey:@"CFBundleGetInfoString"];
					}
				}
			}
			
			// we didn't find info, is this a carbon or classic app?
			if (!result)
				result = [self carbonVersionString:NO];
			
			if (!result)
				result = @"";
			
			[cachedData setGetInfo:result];
		}
    }
	
    return result;
}

- (const char *)UTF8Path;
{
    if (!mv_valid || mv_isComputer)
        return nil;  // computer is not a valid path to a filesystem call
    
    return [[self path] UTF8String];    
}

- (const char *)fileSystemPath;
{
    if (!mv_valid || mv_isComputer)
        return nil;  // computer is not a valid path to a filesystem call
	
    return [[self path] fileSystemRepresentation];
}

- (FSRef*)FSRefPtr;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
    return [[self FSRefObject] ref];
}

- (BOOL)isBrokenAlias;
{
	if (!mv_valid || mv_isComputer)
		return NO;

	BOOL result=NO;
	if (![cachedData isBrokenAlias_initialized:&result])
	{
		@synchronized(self) {
			[self resolvedDesc:NO];
			
			// get the result, set in resolvedDesc
			[cachedData isBrokenAlias_initialized:&result];
		}
	}

	return result;
}

- (BOOL)isServerAlias;
{
	if (!mv_valid || mv_isComputer)
		return NO;

	BOOL result=NO;
	if (![cachedData isServerAlias_initialized:&result])
	{
		@synchronized(self) {
			[self resolvedDesc:NO];
			
			// get the result, set in resolvedDesc
			[cachedData isServerAlias_initialized:&result];
		}
	}
	
    return result;
}

- (NTIcon*)icon;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	NTIcon* result=nil;
	if (![cachedData icon_initialized:&result])
	{
		@synchronized(self) {
			result = [[self FSRefObject] icon];
			
			[cachedData setIcon:result];
		}
	}
	
    return result;
}

- (NSImage*)iconImage;
{
    if (!mv_valid)
        return nil;
	
	NSImage* result=nil;
	if (![cachedData iconImage_initialized:&result])
	{
		@synchronized(self) {
			if (mv_isComputer)
				result = [NSImage imageNamed:NSImageNameComputer];
			else
			{
				NSString* thePath = [self path];
				if (thePath)
					result = [[NSWorkspace sharedWorkspace] iconForFile:thePath];
				else
				{
					if ([self isDirectory])
						result = [[NSWorkspace sharedWorkspace] iconForFile:@"/bin"];  // couldn't get a plain folder?
					else
						result = [[NSWorkspace sharedWorkspace] iconForFileType:(NSString*)kUTTypeData];
				}
			}
			
			[cachedData setIconImage:result];
		}
	}
	
    return result;
}

- (NSImage*)iconImage:(NSInteger)theSize; // copies the image and sets the size, only use if your code relies on the image.size
{
	NSImage* result = [[self iconImage] copy];
	
	[result setSize:NSMakeSize(theSize, theSize)];
	
	return [result autorelease];
}

// only to be used for unix tools that need a path
- (NSString*)pathToResourceFork;
{
    NSString* result=nil;
	
	// only for files
	if ([[self volume] supportsForks])
	{
		if ([self isFile])
			result = [[self path] stringByAppendingFormat:@"%s", _PATH_RSRCFORKSPEC];
	}
	else // ._ is for files and folders
	{
		NSString* thePath = [self path];
		NSString* theName = [thePath lastPathComponent];
		if ([theName length] && ![theName hasPrefix:@"._"])
		{
			theName = [@"._" stringByAppendingString:theName];
			result = [[thePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:theName];
		}
	}
		
    return result;
}

// strips out /Volumes automatically (unless the path is /Volumes)
- (NSArray*)pathComponents:(BOOL)resolveAliases;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:5];
	
    if (!mv_valid || mv_isComputer)
        return result;
    
    NSArray* pathComponents = [[self path] pathComponents];
    int i, cnt = [pathComponents count];
    BOOL stripVolumes = NO;
    NSString* volumes = @"/Volumes";
    NSString* path;
    
    // look for @"/Volumes", be sure not to strip out /Volumes if that is the path
    if ([[self path] length] > [volumes length])
    {
        if ([[self path] compare:volumes options:0 range:NSMakeRange(0, [volumes length])] == NSOrderedSame)
            stripVolumes = YES;
    }
    
    path = @"";
    for (i=0;i<cnt;i++)
    {
        path = [path stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];
        
        if (stripVolumes && (i < 2))
            ;
        else
        {
            NTFileDesc* desc=nil;
            
            if (resolveAliases)
                desc = [NTFileDesc descResolve:path];
            else
                desc = [NTFileDesc descNoResolve:path];
            
            if (desc)
                [result addObject:desc];
        }
    }
    
    return result;
}

- (NSString*)itemInfo;
{
	if (!mv_valid)
        return @"";
	
	NSString* result=nil;
	if (![cachedData itemInfo_initialized:&result])
	{
		@synchronized(self) {
			if ([self isVolume])
				result = [self volumeInfoString];
			else if ([[self volume] isHFS] && ![self isPackage] && [self isDirectory])
			{
				int count = [self valence];
				
				if (count == 0)
					result = [NTLocalizedString localize:@"No items"];
				else if (count == 1)
					result = [NTLocalizedString localize:@"1 item"];
				else if (count > 1)
					result = [NSString stringWithFormat:[NTLocalizedString localize:@"%d items"], count];
			}
			else if ([[self typeIdentifier] isAudio] || [[self typeIdentifier] isMovie])
			{
				result = [[self metadata] displayValueForAttribute:(NSString*)kMDItemDurationSeconds];
				
				if ([result length] && [self isFile])  // return the size for normal files
					result = [NSString stringWithFormat:@"%@ / %@", result, [[NTSizeFormatter sharedInstance] fileSize:[self size]]];
			}
			else if ([[self typeIdentifier] isImageForPreview])
			{
				result = [[self metadata] imageSizeStringMD];

				// not all image meta data contains size
				if (![result length])
					result = [NTCGImage imageSizeString:self];
				
				// also add the file size if we get the image size
				if ([result length])
				{
					if ([self isFile])  // return the size for normal files
						result = [NSString stringWithFormat:@"%@ / %@", result, [[NTSizeFormatter sharedInstance] fileSize:[self size]]];
				}
			}
			
			if (![result length])
			{
				if ([self isFile])  // return the size for normal files
					result = [[NTSizeFormatter sharedInstance] fileSize:[self size]];
			}
			
			if (!result)
				result = @"";
			
			[cachedData setItemInfo:result];
		}
	}
	
    return result;
}

- (NSString*)uniformTypeID;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData uniformTypeID_initialized:&result])
	{
		@synchronized(self) {
			result = [self resourceForKey:NSURLTypeIdentifierKey];
			
			if (!result)
				result = @"";
			
			[cachedData setUniformTypeID:result];
		}
	}
	
	return result;
}

- (BOOL)isInvisible;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isInvisible_initialized:&result])
	{
		@synchronized(self) {
			NSNumber* numResult = [self resourceForKey:NSURLIsHiddenKey];
			if (numResult)
				result = [numResult boolValue]; 
			
			if (!result)
				result = [self isUnixFileThatShouldBeHidden];
			
			[cachedData setIsInvisible:result];
		}
	}
	
    return result;
}

// we are caching the displayName, this is slow, and not so critical if different just used for display
- (NSString*)displayName;
{
    if (!mv_valid)
        return @"";
	
	NSString* result=nil;
	if (![cachedData displayName_initialized:&result])
	{
		@synchronized(self) {
			if (mv_isComputer)
				result = [NTLocalizedString localize:@"Computer" table:@"CocoaTechFoundation"];
			else
			{
				result = [self resourceForKey:NSURLLocalizedNameKey];
				
				// if no displayName, set to name
				if (!result)
					result = [self name];
			}
			
			[cachedData setDisplayName:result];				
		}
	}
	
    return result;
}

- (NSString*)displayPath;
{
	if (mv_isComputer)
		return [self displayName];
	
	if ([self isBootVolume])
		return [self displayName];
	
	return [self path];
}

- (NSString *)kindString;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData kind_initialized:&result])
	{
		@synchronized(self) {
			result = [self resourceForKey:NSURLLocalizedTypeDescriptionKey];
			
			// Apple returns "Alias" for Symlinks
			if ([self isSymbolicLink])
				result = [[NTStringShare sharedInstance] symbolicLinkKindString];
			
			if (!result)
				result = @"";
			
			[cachedData setKind:result];
		}
	}
	
    return result;
}

- (NSString *)architecture;
{
    if (!mv_valid || mv_isComputer)
        return @"";
	
	NSString* result=nil;
	if (![cachedData architecture_initialized:&result])
	{
		@synchronized(self) {
			NSString *path=nil;
			
			if ([self isApplication] && [self isPackage])
			{
				NSBundle* bundle = [NSBundle bundleWithPath:[self path]];
				path = [bundle executablePath];
			}
			else if ([self isExecutableBitSet])
				path = [self path];
			
			result = @"";
			if (path && [self isReadable])
			{
				@try {
					NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
					NSData *data = [fileHandle readDataOfLength:8];
					[fileHandle closeFile];
					
					// open the executable and look for "feedface" (PowerPC), "cafebabe" (Universal), or "cefaedfe" (Intel)
					if (data)
					{
						if ([data length] > 4)
						{
							unsigned marker;
							[data getBytes:&marker length:4];
							
							// convert from big to native and compare to the big endian constant value
							marker = NSSwapBigIntToHost(marker);
							
							if (marker == 0xfeedface)
								result = @"PowerPC";
							else if (marker == 0xcafebabe)
								result = @"Universal";
							else if (marker == 0xcefaedfe)
								result = @"Intel";
						}
					}
				}
				@catch (NSException * e) {
					NSLog(@"%@", [e description]);
				}
				@finally {
				}
			}
			
			[cachedData setArchitecture:result];
		}
	}
	
    return result;
}

- (BOOL)isExtensionHidden;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isExtensionHidden_initialized:&result])
	{
		@synchronized(self) {
			NSNumber* numResult = [self resourceForKey:NSURLHasHiddenExtensionKey];
			if (numResult)
				result = [numResult boolValue]; 
			
			[cachedData setIsExtensionHidden:result];
		}
	}
	
    return result;
}

- (BOOL)isApplication;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isApplication_initialized:&result])
	{
		@synchronized(self) {
			BOOL checkUTI = NO; 
			
			// UTTypeConformsTo is slow, check for other stuff first to avoid the hit 
			if ([self isDirectory] && [[self nameWhenCreated] hasSuffix:@".app"]) 
				checkUTI = YES; 
			else if ([self isDirectory] && [self isBundleBitSet])  // carbon app bundle
				checkUTI = YES; 
			else if ([self isFile])
			{
				// no extension, and type APPL.
				if (([[self nameWhenCreated] rangeOfString:@"."].location == NSNotFound) && ([self type] == 'APPL'))
					checkUTI = YES; 
			}
			
			if (checkUTI)
			{
				if (YES)
				{
					LSRequestedInfo theInfoRequest = kLSRequestBasicFlagsOnly;
					LSItemInfoRecord theInfo;
					
					if (LSCopyItemInfoForRef([self FSRefPtr], theInfoRequest, &theInfo) == noErr)
					{
						if ((theInfo.flags & kLSItemInfoIsApplication) != 0)
							result = YES;
					}
				}
				else // slow?
					result = UTTypeConformsTo((CFStringRef) [self uniformTypeID], kUTTypeApplication);
			}	
			
			[cachedData setIsApplication:result];
		}
	}
	
    return result;
}

- (BOOL)isPackage;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isPackage_initialized:&result])
	{
		@synchronized(self) {
			if ([self isDirectory]) 
			{				
				NSNumber* numResult = [self resourceForKey:NSURLIsPackageKey];
				if (numResult)
					result = [numResult boolValue]; 
			}
			
			[cachedData setIsPackage:result];
		}
	}
	
    return result;
}

- (NTVolume*)volume;
{
    if (!mv_valid || mv_isComputer)
        return nil;

	NTVolume* result=nil;
	if (![cachedData volume_initialized:&result])
	{
		@synchronized(self) {
			result = [[NTVolumeCache sharedInstance] volumeForRefNum:[self volumeRefNum]];
			
			[cachedData setVolume:result];
		}
	}
	
    return result;
}

@end

@implementation NTFileDesc (NTVolume)

- (BOOL)isVolumeReadOnly;
{
	return [[self volume] isReadOnly];
}

- (BOOL)isBootVolume;
{
	FSRef *bootRef = [NTFileDesc bootFSRef];
    
    if (bootRef && [self FSRefPtr])
        return (FSCompareFSRefs([self FSRefPtr], bootRef) == noErr);
	
    return NO;
}

- (BOOL)isExternal;
{
	return [[self volume] isExternal];
}

- (BOOL)isNetwork;
{
	return [[self volume] isNetwork];
}

- (BOOL)isLocalFileSystem
{
	return [[self volume] isLocalFileSystem];
}

- (BOOL)isSlowVolume;  // DVD, CD, Network
{
	NTVolume* volume = [self volume];
	
	// making an assumption here, if readOnly, we are assuming a burned disk of some kind
	return ([volume isNetwork] || [volume isReadOnly] || [volume isAudioCD] || [volume isCDROM] || [volume isDVDROM]);
}

- (BOOL)isEjectable;
{
	return [[self volume] isEjectable];
}

- (NTFileDesc *)mountPoint;
{
	return [[self volume] mountPoint];
}

@end

@implementation NTFileDesc (Setters)

- (NSString*)displayNameForRename;
{
	if ([self isVolume])
		return [self displayName];
	
	// use the name, but must display / instead of colons
	return [[self name] stringByReplacing:@":" with:@"/"];
}

- (NSString*)rename:(NSString*)newName err:(OSStatus*)outErr;
{
    NSString* result=nil;
	OSErr err=noErr;

	// convert slashes to colons for the comparison to the old name, we store the posix name
	newName = [newName stringByReplacing:@"/" with:@":"];
	
	// name must be different
	if (![newName isEqualToString:[self name]])
	{	
		// convert back to slashes for this call to succeed
		newName = [newName stringByReplacing:@":" with:@"/"];
		
		unichar buffer[1024];
		FSRef newRef;
		
		[newName getCharacters:buffer];
		
		err = FSRenameUnicode([self FSRefPtr],
							  [newName length],
							  (const UniChar *) buffer,
							  kTextEncodingUnknown,
							  &newRef);
		
		if (!err)
		{
			// could synchronize in updateFSRefObject, but it's called on creation, so might as well do it here instead to avoid that initial synch
			@synchronized(self) {
				// this dumps the case and is basically recreated from scratch which is what we want
				[self updateFSRefObject:[NTFSRefObject refObject:&newRef catalogInfo:nil bitmap:0 name:nil]];
			}
			
			result = [self name];
		}
	}
	
	if (outErr)
		*outErr = err;
	
    return result;
}

@end

