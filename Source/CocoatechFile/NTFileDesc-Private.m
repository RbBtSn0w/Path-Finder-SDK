//
//  NTFileDesc-Private.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/13/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc-Private.h"
#import "NTVolume.h"
#import "NTAliasFileManager.h"
#import "NTFileDescData.h"
#import "NTFileDescMemCache.h"
#import "NTResourceMgr.h"
#import "NTFSRefObject.h"
#import "NTMetadata.h"

@implementation NTFileDesc (Private)

- (NSURL*)cachedURL:(BOOL)reset;
{
    if (!mv_valid || mv_isComputer)
        return nil;
	
	if (reset)
	{
		@synchronized(self) {		
			[cachedData removeCachedURL];
		}
	}
	
	NSURL* result=nil;
	if (![cachedData cachedURL_initialized:&result])
	{
		@synchronized(self) {				
			result = [self URL];
			[cachedData setCachedURL:result];				
		}			
	}
	
	return result;
}

- (id)resourceForKey:(NSString*)resourceKey;
{	
	id result;
	NSError* error;
	
	error = nil; 
	result = [[self cachedURL:NO] resourceForKey:resourceKey error:&error];
	
	// maybe URL went bad, try again with fresh URL
	if (error) 
	{
		error = nil;
		result = [[self cachedURL:YES] resourceForKey:resourceKey error:&error];
	}
	
	if (error) 
		NSLog(@"%@, key: %@, error: %@", NSStringFromSelector(_cmd), resourceKey, error); 

	return result;
}

- (NSString*)volumeInfoString;
{
	UInt64 freeBytes = [NTFileDesc volumeFreeBytes:self];
	
	UInt64 volumeSize = [NTFileDesc volumeTotalBytes:self];
	UInt64 usedBytes = (volumeSize - freeBytes);
	
	NSString* freeSpace = [[NTSizeFormatter sharedInstance] fileSize:freeBytes];
	NSString* usedSpace = [[NTSizeFormatter sharedInstance] fileSize:usedBytes];
	
	return [NSString stringWithFormat:[NTLocalizedString localize:@"%@, %@ free"], usedSpace, freeSpace];
}	

- (NTFileDesc*)resolvedDesc:(BOOL)resolveIfServerAlias;
{
    if (!mv_valid || mv_isComputer)
        return nil;
		
	NTFileDesc* resolvedDesc=nil;
    @synchronized(self) {
		
		BOOL brokenAlias=NO;
		[cachedData isBrokenAlias_initialized:&brokenAlias];
		
		BOOL serverAlias=NO;
		[cachedData isServerAlias_initialized:&serverAlias];
		
		[cachedData resolvedDesc_initialized:&resolvedDesc];
				
		// did resolved desc go bad?
		if (resolvedDesc && ![resolvedDesc stillExists])
		{
			[cachedData setResolvedDesc:nil];
			resolvedDesc = nil;
		}
		
		if (!resolvedDesc)
		{
			if ([self isAlias] && (!brokenAlias || (serverAlias && resolveIfServerAlias)))
			{
				BOOL isServerAlias, broken = YES;
				resolvedDesc = [NTFileDesc resolveAlias:self resolveIfServerAlias:resolveIfServerAlias isServerAlias:&isServerAlias];
				
				[cachedData setIsServerAlias:isServerAlias];

				if (resolvedDesc && [resolvedDesc isValid])
				{
					[resolvedDesc setAliasDesc:self]; // remember the original file
					
					[cachedData setResolvedDesc:resolvedDesc];
					broken = NO;
				}
				
				[cachedData setIsBrokenAlias:broken];
			}
		}
    }
	
    return resolvedDesc;
}

- (void)setAliasDesc:(NTFileDesc*)desc;
{
	NSString* path = [desc path];
	if (path)
	{
		// we only store the original files path to avoid a double retain problem since the original desc already retains the resolved desc
		[cachedData setOriginalAliasFilePath:path];
	}
}

+ (NTFileDesc*)resolveAlias:(NTFileDesc*)desc resolveIfServerAlias:(BOOL)resolveIfServerAlias isServerAlias:(BOOL*)outIsServerAlias;
{
    NTFileDesc* resolvedDesc=nil;
    BOOL isServerAlias=NO;
    
    if ([desc isAlias])
    {
        if (![desc isValid])
            return nil;
		
        if ([desc isSymbolicLink])
        {
			// I think this is the same as readlink()                    
			char resolved[PATH_MAX];
			char* result = realpath([desc fileSystemPath], resolved);
			
			if (result == nil)
				; // NSLog(@"symlink failed: %@", [desc path]);
			else
			{
				NSString* resolvedPath = [NSString stringWithFileSystemRepresentation:result];
				
				resolvedDesc = [self descNoResolve:resolvedPath];
			}
        }
        else if ([desc isCarbonAlias])
            resolvedDesc = [NTAliasFileManager resolveAliasFile:desc resolveServer:resolveIfServerAlias outIsServerAlias:&isServerAlias];
        else if ([desc isPathFinderAlias])
            resolvedDesc = [NTAliasFileManager resolvePathFinderAliasFile:desc resolveServer:resolveIfServerAlias outIsServerAlias:&isServerAlias];
    }
	
    if (outIsServerAlias)
        *outIsServerAlias = isServerAlias;
	
    if ([resolvedDesc isValid])
        return resolvedDesc;
	
    return nil;
}

// old style 'vers' resource version
- (NSString*)carbonVersionString:(BOOL)shortVersion;
{
    NTResourceMgr *mgr = [NTResourceMgr mgrWithDesc:self];
    NSData *versRsrc = [mgr resourceForType:'vers' resID:1];
	
    if (versRsrc)
    {
        VersRec versRecP;
		
        // fill in the structure
        [versRsrc getBytes:&versRecP length:sizeof(VersRec)];
		
        // • Get at the version record so we can extract the short version string
        if (shortVersion)
        {
            UInt8 minor = versRecP.numericVersion.minorAndBugRev; // shares a byte
            UInt8 bugRev = versRecP.numericVersion.minorAndBugRev; // shares a byte
            
            minor = minor >> 4;
            bugRev &= 0x0F;
			
            return [NSString stringWithFormat:@"%d.%d.%d", versRecP.numericVersion.majorRev, minor, bugRev];
        }
        else
            return [NSString stringWithPString:versRecP.shortVersion];
    }
	
    return @"";
}

// in Tiger, .hidden was removed, but there were a few files that were not correctly hidden
// hack that might be removed in future OSes
- (BOOL)isUnixFileThatShouldBeHidden;
{
	static NTFileDesc* mach_desc = nil;
	static NTFileDesc* machsym_desc = nil;
	static NTFileDesc* machkernel_desc = nil;
		
    if (!mach_desc)
		mach_desc = [[NTFileDesc descNoResolve:@"/mach"] retain];
	
    if (!machsym_desc)
		machsym_desc = [[NTFileDesc descNoResolve:@"/mach.sym"] retain];

	if (!machkernel_desc)
		machkernel_desc = [[NTFileDesc descNoResolve:@"/mach_kernel.ctfsys"] retain];

	// trying to make things faster
	if ([self isOnBootVolume] && [self parentIsVolume])
	{
		if ([self isEqualToDesc:mach_desc])
			return YES;
		else if ([self isEqualToDesc:machsym_desc])
			return YES;
		else if ([self isEqualToDesc:machkernel_desc])
			return YES;
	}
	
	return NO;
}

- (void)initializeSizeInfo;
{
	UInt64 dataLogical = [[self FSRefObject] dataLogicalSize];
	UInt64 rsrcLogical = [[self FSRefObject] rsrcLogicalSize];
	UInt64 dataPhysical = [[self FSRefObject] dataPhysicalSize];
	UInt64 rsrcPhysical = [[self FSRefObject] rsrcPhysicalSize];
	
	// I've seen some cases with root files that show 0 as physical, but nonzero as logical.  Don't know why, but this adjusts that
	// /usr/share/man/man8/spindump.8 for example
	if (dataPhysical == 0 && dataLogical > 0)
		dataPhysical = dataLogical;
	if (rsrcPhysical == 0 && rsrcLogical > 0)
		rsrcPhysical = rsrcLogical;
	
	// total
	[cachedData setFileSize:dataLogical + rsrcLogical];	
	[cachedData setPhysicalFileSize:dataPhysical + rsrcPhysical];
	
	// data fork
	[cachedData setDataForkSize:dataLogical];
	[cachedData setDataForkPhysicalSize:dataPhysical];
	
	// rsrc fork
	[cachedData setRsrcForkSize:rsrcLogical];
	[cachedData setRsrcForkPhysicalSize:rsrcPhysical];	
}


@end
