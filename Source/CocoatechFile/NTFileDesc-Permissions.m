//
//  NTFileDesc-Permissions.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 3/19/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTFileDesc.h"
#import "NTFileDescData.h"
#import "NTFileDesc-Private.h"

@interface NTFileDesc (PermissionsACL)
- (BOOL)isMovableACL;
- (BOOL)isReadableACL;
- (BOOL)isWritableACL;
- (BOOL)isDeletableACL;
- (BOOL)isExecutableACL;
@end

@interface NTFileDesc (PermissionsSymLink)
- (BOOL)isMovableSymLink;
- (BOOL)isReadableSymLink;
- (BOOL)isWritableSymLink;
- (BOOL)isDeletableSymLink;
- (BOOL)isExecutableSymLink;
@end

@implementation NTFileDesc (Permissions)

- (BOOL)isReadable;
{
    if (!mv_valid)
        return NO;
	else if (mv_isComputer) // computer fake directory is readable
		return YES;
	
	BOOL result=NO;
	if (![cachedData isReadable_initialized:&result])
	{
		@synchronized(self) {
			if ([self isSymbolicLink])
				result = [self isReadableSymLink];			
			else
				result = [self isReadableACL];
			
			[cachedData setIsReadable:result];
		}
	}
	
	return result;
}

- (BOOL)isWritable;
{	
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isWritable_initialized:&result])
	{
		@synchronized(self) {
			if ([self isSymbolicLink])
				result = [self isWritableSymLink];			
			else
				result = [self isWritableACL];
			
			[cachedData setIsWritable:result];
		}
    }
	
    return result;
}

- (BOOL)isExecutable;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isExecutable_initialized:&result])
	{
		@synchronized(self) {
			if ([self isSymbolicLink])
				result = [self isExecutableSymLink];			
			else
				result = [self isExecutableACL];
			
			[cachedData setIsExecutable:result];
		}
	}
	
	return result;
}

- (BOOL)isDeletable;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isDeletable_initialized:&result])
	{
		@synchronized(self) {
			if (![self isVolume])
			{
				if ([self isSymbolicLink])
					result = [self isDeletableSymLink];			
				else
					result = [self isDeletableACL];				
			}
			
			[cachedData setIsDeletable:result];
        }
    }
	
    return result;
}

// can we move the file?
- (BOOL)isMovable;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isMovable_initialized:&result])
	{
		@synchronized(self) {
			if ([self isSymbolicLink])
				result = [self isMovableSymLink];			
			else
				result = [self isMovableACL];
			
			[cachedData setIsMovable:result];
        }
    }
	
    return result;
}

- (BOOL)isRenamable;
{
    if (!mv_valid || mv_isComputer)
        return NO;
	
	BOOL result=NO;
	if (![cachedData isRenamable_initialized:&result])
	{
		@synchronized(self) {
			if (![self isLocked])  // took out the "![self isNameLocked]" check, Finder ignores it
			{
				// are we a volume?
				if ([self isVolume])
				{
					if (![self isVolumeReadOnly] && ![self isNetwork])
						result =  YES;
				}
				else
					result = [self isMovable];  // same requirements as movable
			}
			
			[cachedData setIsRenamable:result];
        }
    }
	
    return result;
}

@end

@implementation NTFileDesc (PermissionsSymLink)

- (BOOL)isDeletableSymLink;
{
	BOOL result = [[NSFileManager defaultManager] isDeletableFileAtPath:[self path]];
	
	return result;	
}

/*
 Each level is independent. The user who is trying to access the file determines what level will be used to set permissions.
 
 If the user is the owner of the file, the owner permissions will be used.
 If the user is not the owner of the file but is in the same group as the file, the group permissions will be used.
 If the user is not the owner of the file and is not in the same group as the file, the other permissions will be used.
 
 NOTE: access() resolves symlinks
 */

- (BOOL)isMovableSymLink;
{
	BOOL result=NO;
	NTFileDesc* parentDesc = [self parentDesc];
	
	if ([parentDesc isWritable]  && ![self isLocked]) // can't move locked files (same as finder)
	{
		result = YES;
		
		// directories keep track of their parent (..), so we need to be writable to be movable.  Files do not keep track of the parent (..)
		if ([self isDirectory])
			result = [self isWritable];
		
		if (result)
		{
			// A directory whose `sticky bit' is set becomes an append-only directory,
			// or, more accurately, a directory in which the deletion of files is
			// restricted.  A file in a sticky directory may only be removed or renamed
			// by a user if the user has write permission for the directory and the user
			// is the owner of the file, the owner of the directory, or the super-user.
			if ([parentDesc isStickyBitSet] && ![[NTUsersAndGroups sharedInstance] isRoot])
			{
				result = NO;
				
				int myUserID = [[NTUsersAndGroups sharedInstance] userID];
				
				// owner of the file or owner of the parent directory
				if (([parentDesc ownerID] == myUserID) || ([self ownerID] == myUserID))
					result = YES;
			}
		}
	}
	
	return result;
}

- (BOOL)isExecutableSymLink;
{
	BOOL result=NO;
	
	// are we logged in as root?
	if ([[NTUsersAndGroups sharedInstance] isRoot])
		result = YES;
	
	if (!result)
	{
		BOOL isOwner = ([[NTUsersAndGroups sharedInstance] userID] == [self ownerID]);
		
		// test if owner
		if (!result)
		{
			if (isOwner)
				result = (([self posixPermissions] & S_IXUSR) == S_IXUSR);
		}
		
		// test if group
		// !isOwner is what the OS does.  If we are the owner and don't have perm, don't bother checking the group
		if (!result && !isOwner)
		{
			BOOL isGroup = (([[NTUsersAndGroups sharedInstance] groupID] == [self groupID]) || 
							[[NTUsersAndGroups sharedInstance] userIsMemberOfGroup:[self groupID]]);
			
			if (isGroup)
				result = (([self posixPermissions] & S_IXGRP) == S_IXGRP);
			
			// is the item executable by everyone?
			if (!result)
			{
				if (!isGroup && !isOwner)
					result = (([self posixPermissions] & S_IXOTH) == S_IXOTH);			
			}
		}
	}
	
	return result;
}

- (BOOL)isWritableSymLink;
{
	BOOL result=NO;
	
	// are we on a CD rom, or is the item locked?
	if (![self isVolumeReadOnly] && ![self isLocked])
	{
		// are we logged in as root?
		if ([[NTUsersAndGroups sharedInstance] isRoot])
			result = YES;
		
		if (!result)
		{
			BOOL isOwner = ([[NTUsersAndGroups sharedInstance] userID] == [self ownerID]);
			
			// then if we are the owner, is there owner permissions
			if (!result)
			{
				if (isOwner)
					result = (([self posixPermissions] & S_IWUSR) == S_IWUSR);
			}
			
			// !isOwner is what the OS does.  If we are the owner and don't have perm, don't bother checking the group
			if (!result && !isOwner)
			{
				// checking group can be slow
				BOOL isGroup = (([[NTUsersAndGroups sharedInstance] groupID] == [self groupID]) || 
								[[NTUsersAndGroups sharedInstance] userIsMemberOfGroup:[self groupID]]);
				
				if (isGroup)
					result = (([self posixPermissions] & S_IWGRP) == S_IWGRP);
				
				// is the item writable by everyone?
				if (!result)
				{
					// other is only valid if we are not the group or owner
					if (!isGroup && !isOwner)
						result = (([self posixPermissions] & S_IWOTH) == S_IWOTH);	
				}
			}
		}
	}
	
	return result;
}

- (BOOL)isReadableSymLink;
{
	BOOL result=NO;
	
	// are we logged in as root?
	if ([[NTUsersAndGroups sharedInstance] isRoot])
		result = YES;
	
	if (!result)
	{
		BOOL isOwner = ([[NTUsersAndGroups sharedInstance] userID] == [self ownerID]);
		
		// test if owner
		if (!result)
		{
			if (isOwner)
				result = (([self posixPermissions] & S_IRUSR) == S_IRUSR);
		}
		
		// test if group
		// !isOwner is what the OS does.  If we are the owner and don't have perm, don't bother checking the group
		if (!result && !isOwner)
		{
			BOOL isGroup = (([[NTUsersAndGroups sharedInstance] groupID] == [self groupID]) || 
							[[NTUsersAndGroups sharedInstance] userIsMemberOfGroup:[self groupID]]);
			
			if (isGroup)
				result = (([self posixPermissions] & S_IRGRP) == S_IRGRP);
			
			// is the item readable by everyone?
			if (!result)
			{
				if (!isGroup && !isOwner)
					result = (([self posixPermissions] & S_IROTH) == S_IROTH);			
			}
		}
	}
	
	return result;
}

@end

@implementation NTFileDesc (PermissionsACL)

- (BOOL)isDeletableACL;
{
	BOOL result = (access([self fileSystemPath], _DELETE_OK) == 0);
	
	return result;	
}

- (BOOL)isMovableACL;
{
	BOOL result=NO;
	
	// moving a directory, the item needs to be appendable to update ".." which is the pointer to it's parent.
	if ([self isDirectory])
		result = (access([self fileSystemPath], _DELETE_OK | _APPEND_OK) == 0);
	else
		result = (access([self fileSystemPath], _DELETE_OK) == 0);
	
	return result;
}

- (BOOL)isWritableACL;
{
	BOOL result = (access([self fileSystemPath], _WRITE_OK) == 0);
	
	return result;	
}

- (BOOL)isReadableACL;
{
	BOOL result = (access([self fileSystemPath], _READ_OK) == 0);
	
	return result;	
}

- (BOOL)isExecutableACL;
{
	BOOL result = (access([self fileSystemPath], _EXECUTE_OK) == 0);
	
	return result;	
}

@end


