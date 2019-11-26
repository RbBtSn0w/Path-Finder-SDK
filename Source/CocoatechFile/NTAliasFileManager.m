//
//  NTAliasFileManager.m
//  CocoatechFile
//
//  Created by sgehrman on Fri Jul 13 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTAliasFileManager.h"
#import <sys/stat.h>
#import "NTFileModifier.h"
#import "NTIconFamily.h"
#import "NTAlias.h"
#import "NTImageStore.h"
#import "NSImage-CocoatechFile.h"

@interface NTAliasFileManager (Private)
+ (NTFileDesc*)doCreateAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath dataFork:(BOOL)dataFork;
+ (NTFileDesc*)doResolveAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias dataFork:(BOOL)dataFork;
@end

@implementation NTAliasFileManager

+ (BOOL)isMountPointSyntheticAliasFile:(NTFileDesc*)theDesc;
{
	if ([theDesc isAliasBitSet])
	{
		// IMPORTANT: Carbon programs should use the Alias Manager (FSIsAliasFile and FSResolveAliasFile, or their older equivalents) 
		// to detect and resolve alias files. Do not try to interpret alias files by hand. Doing so is likely to cause future incompatibilities.
		// For debugging purposes only, a mount point synthetic alias file has the kIsAlias bit set in the Finder flags and has file type 'lcmt' and file creator 'rhap'.

		if ([theDesc type] == 'lcmt' && [theDesc creator] == 'rhap')
			return YES;
	}
	
	return NO;
}

+ (NTFileDesc*)resolveMountPointSyntheticAliasFile:(NTFileDesc*)desc;
{
    NTFileDesc *resolvedDesc = nil;
    Boolean targetIsFolder, wasAliased;
    OSErr err;
    Boolean resolveChains = true;
    FSRef fsRef = *[desc FSRefPtr];

	err = FSResolveAliasFile(&fsRef, resolveChains, &targetIsFolder, &wasAliased);	

    if (err == noErr && wasAliased)
        resolvedDesc = [NTFileDesc descFSRef:&fsRef];

    return resolvedDesc;
}

+ (NTFileDesc*)createAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath;
{
    NTFileDesc* aliasFile = [self doCreateAliasFile:desc atPath:destPath dataFork:NO];
    
	if (aliasFile)
	{
		// sets the custom icon and type/creator
		[self setupAliasFile:aliasFile forDesc:desc];
	}
	
    return aliasFile;
}

+ (NTFileDesc*)createPathFinderAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath;
{
    NTFileDesc* aliasDesc = [self doCreateAliasFile:desc atPath:destPath dataFork:YES];
    
    if (aliasDesc)
    {        
        // rename with extension
        if (![aliasDesc isPathFinderAlias])  // check if the extension is correct already
        {
            NSString* newName = [[aliasDesc name] strictStringByDeletingPathExtension];
            
            newName = [newName stringByAppendingPathExtension:kPathFinderAliasExtension];

            [aliasDesc rename:newName err:nil];
                    
            if (![aliasDesc isValid])
                aliasDesc = nil;
        }
                
        if ([aliasDesc isValid])
        {
            NTIconFamily* iconFamily = [NTIconFamily iconFamilyWithIconOfFile:desc];
            NSImage *image = [iconFamily image];
            
            // add the alias badge to all imageReps so it looks good
            image = [image imageWithBadge:[NTMS aliasBadge]];
                
            // convert back to iconFamily
            iconFamily = [NTIconFamily iconFamilyWithImage:image];
            
            // now set that icon family as a custom icon
            [iconFamily setAsCustomIconForFile:aliasDesc];
            
            // hide extension
            [NTFileModifier setExtensionHidden:YES desc:aliasDesc];
        }
    }
    
    return aliasDesc;
}

+ (NTFileDesc*)resolveAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias;
{
	return [self doResolveAliasFile:desc resolveServer:resolveServer outIsServerAlias:outIsServerAlias dataFork:NO];
}

+ (NTFileDesc*)resolvePathFinderAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias;
{
	return [self doResolveAliasFile:desc resolveServer:resolveServer outIsServerAlias:outIsServerAlias dataFork:YES];
}

// alias handle becomes owned by the Resource manager, so don't dispose yourself
+ (BOOL)addAliasResource:(AliasHandle)alias toFile:(FSRef*)ref dataFork:(BOOL)dataFork;
{
	HFSUniStr255 forkName;
	ResFileRefNum refNum;
	OSErr err;
	
	if (dataFork)
		FSGetDataForkName(&forkName);
	else
		FSGetResourceForkName(&forkName);
	
	err = FSOpenResourceFile(ref, forkName.length,forkName.unicode, fsRdWrPerm, &refNum);
	if (!err)
	{
		short oldResFile = CurResFile();
		UseResFile(refNum);
		
		// must remove old one?  seems to be appending the data which is strange
		Handle oldHandle = Get1Resource(rAliasType, 0);
		if (oldHandle)
		{
			RemoveResource(oldHandle);
			UpdateResFile(refNum);
			DisposeHandle(oldHandle);
		}
		
		AddResource((Handle) alias, rAliasType, 0, "\p");
		UpdateResFile(refNum);
		ReleaseResource((Handle)alias);
		
		UseResFile(oldResFile);
		
		CloseResFile(refNum);
		
		if (err == noErr)
			return YES;
	}
	
	return NO;
}

// updates the custom icon and type/creator for an alias file
+ (void)setupAliasFile:(NTFileDesc*)aliasFile forDesc:(NTFileDesc*)desc;
{
	FileInfo fileInfo = *[desc fileInfo];
	
	// set alias types for special folders	
	OSType type = [NTAlias fileTypeForAliasFileOfDesc:desc];
	if (type)
	{
		fileInfo.fileType = type;
		fileInfo.fileCreator = 'MACS';
	}
	
	fileInfo.finderFlags = kIsAlias; // set the alias finder flag
	
	// set the file information or the new file
	[NTFileModifier setFileInfo:&fileInfo desc:aliasFile];
	
	// files and applications always get a custom icon
	if ([desc isFile] || [desc isPackage])
	{
		// for files, we always set a custom icon so the alias file matches the original
		[[NTIconFamily iconFamilyWithIconOfFile:desc] setAsCustomIconForFile:aliasFile];
	}
	else if ([desc isDirectory])
	{
		// directories only get a custom icon if they already have a custom icon
		if ([NTIconFamily hasCustomIconForDirectory:desc])
			[[NTIconFamily iconFamilyWithIconOfFile:desc] setAsCustomIconForDirectory:aliasFile];
	}            
}

@end

@implementation NTAliasFileManager (Private)

+ (NTFileDesc*)doCreateAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath dataFork:(BOOL)dataFork;
{
    AliasHandle alias = [NTAlias aliasHandleForDesc:desc];
    OSStatus err=-666;
    
    if (alias)
    {
        FSRef parentRef, destRef;
        NSString* destName = [destPath lastPathComponent];
        NSString* parentPath = [destPath stringByDeletingLastPathComponent];
        unichar unicodeName[[destName length]];
        HFSUniStr255 forkName;
                
        // file name must be an hfs plus compatible name : must be coverted to /
        destName = [destName stringByReplacing:@":" with:@"/"];
        
        [destName getCharacters:unicodeName];
        
        if (dataFork)
            FSGetDataForkName(&forkName);
        else
            FSGetResourceForkName(&forkName);
                
        err = FSPathMakeRef((const UInt8 *)[parentPath UTF8String], &parentRef, NULL);
        if (err) return nil;
        
        err = FSCreateResourceFile(&parentRef, [destName length], unicodeName, 0, nil, forkName.length,forkName.unicode, &destRef, nil);
        if (err) return nil;
        
		BOOL success = [self addAliasResource:alias toFile:&destRef dataFork:dataFork];
		if (success)
			return [NTFileDesc descFSRef:&destRef];
    }
	
    return nil;
}

+ (NTFileDesc*)doResolveAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias dataFork:(BOOL)dataFork;
{
	NTFileDesc* result = nil;
	
	NSData* aliasData = [NTAlias aliasResourceFromAliasFile:desc dataFork:dataFork];
	if (aliasData)
	{
		BOOL wasChanged;
		AliasHandle aliasHandle = (AliasHandle)[aliasData carbonHandle];
		
		result = [NTAlias resolveAlias:desc aliasHandle:aliasHandle resolveIfRequiresUI:resolveServer outAliasRequiresUIToResolve:outIsServerAlias outWasChanged:&wasChanged];
		
		DisposeHandle((Handle) aliasHandle);
	}
	else
	{
		// must ve a mountPointSyntheticAliasFile
		if ([self isMountPointSyntheticAliasFile:desc])
		{
			if (resolveServer)
				result = [self resolveMountPointSyntheticAliasFile:desc];
			else
			{
				// not sure if this is necessary.  I wanted to treat it like a network volume incase there were cases where this would trigger a mount.  Not sure how they are used exactly
				if (outIsServerAlias)
					*outIsServerAlias = YES;
			}
		}
	}
	
	return result;
}

@end