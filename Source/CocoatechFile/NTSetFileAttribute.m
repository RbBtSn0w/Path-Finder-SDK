//
//  NTSetFileAttribute.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 8/20/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTSetFileAttribute.h"
#import "NTFinderController.h"
#import <unistd.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/xattr.h>

@interface NSString (PrivateCategory)
- (FSRef*)FSRefPtr:(FSRef*)ref;

- (UInt16)modeBits;
- (BOOL)setModeBits:(UInt16)mode;

- (FileInfo*)fileInfo:(FileInfo*)fileInfo;
- (BOOL)setFileInfo:(FileInfo*)fileInfo;
@end

@implementation NTSetFileAttribute

+ (unsigned)permissions:(int*)outUser group:(int*)outGroup path:(NSString*)path;
{
	struct stat statStruct;
	
	if (lstat([path fileSystemRepresentation], &statStruct) == 0)
	{
		if (outUser)
			*outUser =  statStruct.st_uid;
		
		if (outGroup)
			*outGroup = statStruct.st_gid;
		
		return (statStruct.st_mode & ACCESSPERMS);
	}
	else
		NSLog(@"lstat: %s (%@)", strerror(errno), path);
	
	return 0;
}

+ (BOOL)setPermissions:(unsigned long)permissions path:(NSString*)path;
{
    // use the Authentication stuff if not the owner of the file
    BOOL result;
	
	mode_t mode = [path modeBits];
	
	// just set the permission bits, leave the rest along
	mode &= ~ACCESSPERMS;  // clear permission bits
	mode |= (ACCESSPERMS & permissions);
	
	result = [path setModeBits:mode];
	
    return result;
}

+ (BOOL)setStickyBit:(BOOL)set path:(NSString*)path;
{
    BOOL result;
    mode_t mode = [path modeBits];
	
    if (set)
        mode |= S_ISVTX;
    else
        mode &= ~S_ISVTX;
	
	result = [path setModeBits:mode];
	
    return result;
}

+ (BOOL)setGroup:(int)groupID path:(NSString*)path;
{
	// use the Authentication stuff if not the owner of the file	
	BOOL result = (lchown([path fileSystemRepresentation], -1, groupID) == 0);
	
	if (!result)
		NSLog(@"setGroup: %s (%@)", strerror(errno), path);
	
    return result;	
}

+ (BOOL)setOwner:(int)userID path:(NSString*)path;
{
    // use the Authentication stuff if not the owner of the file
    BOOL result = (lchown([path fileSystemRepresentation], userID, -1) == 0);
	
	if (!result)
		NSLog(@"setOwner: %s (%@)", strerror(errno), path);
	
    return result;
}

+ (BOOL)setAttributeModificationDate:(NSDate*)date path:(NSString*)path;
{
	BOOL result;
	
	// BUG: setting kFSCatInfoAttrMod is broken, but we at least can touch the date which is what people normally want anyway
    if (!date)
	{
		FileInfo fileInfo;
		[path fileInfo:&fileInfo];
		result = [path setFileInfo:&fileInfo];		
	}
	else
	{
		// this is broken, but maybe Leopard will fix
		FSCatalogInfo catalogInfo;
		
		catalogInfo.attributeModDate = [NSDate UTCDateTimeFromNSDate:date];
		
		FSRef ref;
		OSErr err = FSSetCatalogInfo([path FSRefPtr:&ref], kFSCatInfoAttrMod, &catalogInfo);
		
		result = (err == noErr);
	}
	
	return result;
}

// pass nil for date to set to current date and time
+ (BOOL)setModificationDate:(NSDate*)date path:(NSString*)path;
{
    FSCatalogInfo catalogInfo;
	
    if (!date)
        date = [NSDate date];
	
    catalogInfo.contentModDate = [NSDate UTCDateTimeFromNSDate:date];
	
	OSErr err=noErr;
	FSRef ref;
	
	if ([path FSRefPtr:&ref])
		err = FSSetCatalogInfo(&ref, kFSCatInfoContentMod, &catalogInfo);
	
	return (err == noErr);
}

+ (BOOL)setCreationDate:(NSDate*)date path:(NSString*)path;
{
    FSCatalogInfo catalogInfo;
	FSRef ref;
	
    if (!date)
        date = [NSDate date];
	
    catalogInfo.createDate = [NSDate UTCDateTimeFromNSDate:date];
	
    return (FSSetCatalogInfo([path FSRefPtr:&ref], kFSCatInfoCreateDate, &catalogInfo) == noErr);
}

+ (BOOL)setLock:(NSNumber*)stateValue path:(NSString*)path;
{
	FSRef ref;
	
    if ([path FSRefPtr:&ref])
    {
		FSCatalogInfo catalogInfo;
		OSStatus err;
		BOOL set=YES;
		
        err = FSGetCatalogInfo(&ref, kFSCatInfoNodeFlags, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr)
        {
			switch ([stateValue intValue])
			{
				case NTMixedState:
					set = !((catalogInfo.nodeFlags & kFSNodeLockedMask) != 0);
					break;
				case NTOffState:
					set = NO;
					break;
				case NTOnState:
					set = YES;
					break;
			}
			
            if (set)
                catalogInfo.nodeFlags |= kFSNodeLockedMask;
            else
                catalogInfo.nodeFlags &= ~kFSNodeLockedMask;
			
            err = FSSetCatalogInfo(&ref, kFSCatInfoNodeFlags, &catalogInfo);
        }
		
        return (err == noErr);
    }
	
    return NO;
}

+ (BOOL)setType:(OSType)type path:(NSString*)path;
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
    [attributes setObject:[NSNumber numberWithInt:type] forKey:NSFileHFSTypeCode];
    return [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:path error:nil];
}

+ (BOOL)setCreator:(OSType)creator path:(NSString*)path;
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
    [attributes setObject:[NSNumber numberWithInt:creator] forKey:NSFileHFSCreatorCode];
    return [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:path error:nil];
}

// labels are 0 for none and 1-7 for colors
+ (BOOL)setLabel:(int)label path:(NSString*)path;
{
	FileInfo fileInfo;
	
	if ([path fileInfo:&fileInfo])
	{
        if (label >= 0 && label <= 7)
        {
            UInt16 newLabel = label;
			
            newLabel = (newLabel << 1);
			
            fileInfo.finderFlags &= ~kColor;
            fileInfo.finderFlags |= (newLabel & kColor);
			
            return [path setFileInfo:&fileInfo];
        }
    }
	
    return NO;
}

+ (BOOL)setLength:(UInt64)length path:(NSString*)path;
{
    int result = truncate([path fileSystemRepresentation], length);
	
    return (result == 0);
}

+ (BOOL)setExtensionHidden:(NSNumber*)stateValue path:(NSString*)path;
{	
	FSRef ref;
	BOOL set=YES;
	
	// get the ref
	[path FSRefPtr:&ref];
	
	switch ([stateValue intValue])
	{
		case NTMixedState:
		{
			CFTypeRef outBool;
			OSStatus err = LSCopyItemAttribute(&ref,
											   kLSRolesAll,
											   kLSItemExtensionIsHidden, &outBool);
			
			if (!err)
			{
				set = ![(NSNumber*) outBool boolValue];
				CFRelease(outBool);
			}			
		}
			break;
		case NTOffState:
			set = NO;
			break;
		case NTOnState:
			set = YES;
			break;
	}
	
	OSStatus err = LSSetExtensionHiddenForRef(&ref, set);
	
	return (err == noErr);
}

+ (BOOL)set:(NSNumber*)stateValue finderFlag:(short)finderFlag path:(NSString*)path;
{
	FileInfo fileInfo;
	BOOL set=YES;
	
	if ([path fileInfo:&fileInfo])
	{        		
		switch ([stateValue intValue])
		{
			case NTMixedState:
				set = !((fileInfo.finderFlags & finderFlag) != 0);
				break;
			case NTOffState:
				set = NO;
				break;
			case NTOnState:
				set = YES;
				break;
		}
		
        if (set)
            fileInfo.finderFlags |= finderFlag;
        else
            fileInfo.finderFlags &= ~finderFlag;
        
        return [path setFileInfo:&fileInfo];
    }
    
    return NO;
}

+ (BOOL)setFinderPosition:(NSPoint)point path:(NSString*)path;
{
	FileInfo fileInfo;
	
	if ([path fileInfo:&fileInfo])
	{
        Point carbonPoint;
		
        carbonPoint.h = (short) point.x;
        carbonPoint.v = (short) point.y;
        
        fileInfo.location = carbonPoint;
		
        return [path setFileInfo:&fileInfo];
    }
	
    return NO;
}

+ (void)setSpotlightCommentsUsingTheFinder:(NSString*)comments path:(NSString*)path;
{
	if (!comments)
		comments = @"";
	
	// comments can be zero length to clear comments
	if ([path length])
	{
		NSString* scriptText = [NSString stringWithFormat:@"Tell Application \"Finder\" \n set fileAlias to (\"%@\" as POSIX file) \n set comment of item fileAlias to \"%@\" \n end tell", path, comments];
		
		NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:scriptText] autorelease];
		NSDictionary *errorInfo=nil;
		
		// Execute the script, compiling it first if it is not already compiled.  Return the result of executing the script, or nil and a pointer to an error information dictionary for failure.
		[script executeAndReturnError:&errorInfo];
		
		if (errorInfo)
			NSLog(@"failed: %@\n\n%@", scriptText, [errorInfo description]);
	}
}

// This works, but the Finder only displays comments in the .DS_Store file
+ (void)setSpotlightCommentsManually:(NSString*)comments path:(NSString*)path;
{
	if (!comments)
		comments = @"";
	
	if ([path length])
	{
		NTFileDesc *desc = [NTFileDesc descNoResolve:path];
		
		if ([desc isValid])
		{
			if ([comments length])
			{
				NSError* error=nil;
				NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:comments format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
				
				if (plistData && !error)
					setxattr([desc fileSystemPath], "com.apple.metadata:kMDItemFinderComment", [plistData bytes], [plistData length], 0, XATTR_NOFOLLOW);
			}
			else
				removexattr([desc fileSystemPath], "com.apple.metadata:kMDItemFinderComment", XATTR_NOFOLLOW);
		}
	}
}

+ (void)setSpotlightComments:(NSString*)comments path:(NSString*)path;
{	
	// only use Finder if it's running
	if ([[NTFinderController sharedInstance] isFinderRunning])
		[self setSpotlightCommentsUsingTheFinder:comments path:path];
	else
		[self setSpotlightCommentsManually:comments path:path];
}

@end

// ====================================================================================
// ====================================================================================

@implementation NSString (PrivateCategory)

- (FSRef*)FSRefPtr:(FSRef*)ref;
{
	OptionBits options = kFSPathMakeRefDefaultOptions;
	
	// never follow symlinks
	options |= kFSPathMakeRefDoNotFollowLeafSymlink;
	
	OSStatus status =  FSPathMakeRefWithOptions((const UInt8 *)[self UTF8String], options, ref, nil);
	
	if (status == noErr)
		return ref;
	
	return nil;
}

- (FileInfo*)fileInfo:(FileInfo*)fileInfo
{
	FSRef ref;
	if ([self FSRefPtr:&ref])
	{
		OSStatus err;
		FSCatalogInfo catalogInfo;
		
        err = FSGetCatalogInfo(&ref, kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr)
        {
            *fileInfo = *((FileInfo*)catalogInfo.finderInfo);
			
			return fileInfo;
        }
    }
	
	return nil;
}

- (BOOL)setFileInfo:(FileInfo*)fileInfo;
{
	FSRef ref;
	if ([self FSRefPtr:&ref])
	{
        FSCatalogInfo catalogInfo;
		
        *((FileInfo*)&catalogInfo.finderInfo) = *fileInfo;
		
		OSStatus err = FSSetCatalogInfo(&ref, kFSCatInfoFinderInfo, &catalogInfo);
		
		if (!err)
			return YES;
    }
	
	return NO;
}

- (UInt16)modeBits;
{
	FSRef ref;
	if ([self FSRefPtr:&ref])
	{
		OSStatus err;
		FSCatalogInfo catalogInfo;
		
        err = FSGetCatalogInfo(&ref, kFSCatInfoPermissions, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr)
        {
			FSPermissionInfo* permPtr = (FSPermissionInfo*) &(catalogInfo.permissions);
			
			return permPtr->mode;
        }
    }
	
	return 0;
}

- (BOOL)setModeBits:(UInt16)mode;
{
	FSRef ref;
	
    if ([self FSRefPtr:&ref])
    {
		FSCatalogInfo catalogInfo;
		OSStatus err;
		
        err = FSGetCatalogInfo(&ref, kFSCatInfoPermissions, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr)
        {
			((FSPermissionInfo*)&(catalogInfo.permissions))->mode = mode;
			
            err = FSSetCatalogInfo(&ref, kFSCatInfoPermissions, &catalogInfo);
        }
		
        return (err == noErr);
    }
	
    return NO;
}

@end
