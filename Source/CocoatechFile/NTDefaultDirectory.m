//
//  NTDefaultDirectory.m
//  CocoatechFile
//
//  Created by sgehrman on Tue Jun 05 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTDefaultDirectory.h"
#import "NTPathUtilities.h"
#import <sys/stat.h>
#import <sys/fcntl.h>
#import "NTFileCreation.h"

@interface NTDefaultDirectory ()
@property (nonatomic, retain) NSMutableDictionary *paths;
@property (nonatomic, retain) NSArray* applicationDirectories_storage;
@end

@interface NTDefaultDirectory (Private)
- (NSString *)findSystemFolderType:(int)folderType forDomain:(int)domain createFolder:(BOOL)createFolder;
- (NSString*)pathForKey:(NSString*)theKey;
- (void)setPath:(NSString*)thePath forKey:(NSString*)theKey;
@end

#define kPluginsFolderName @"PlugIns"  // this matches NSBundle
#define kSettingsFolderName @"Settings"
#define kCoreDataFolderName @"Core Data"

@implementation NTDefaultDirectory

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize paths, applicationDirectories_storage;

- (id)init;
{
	self = [super init];
	
	self.paths = [NSMutableDictionary dictionary];
	
	return self;
}

+ (NTDefaultDirectory*)sharedInstance;
{
	return [super sharedInstance];
}

- (void)dealloc;
{
	self.paths = nil;
    self.applicationDirectories_storage = nil;

    [super dealloc];
}

// home directories
- (NSString*)homePath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = NSHomeDirectory();
		
		[self setPath:result forKey:theKey];
    }

	return result;
}

- (NSString*)favoritesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kFavoritesFolderType forDomain:kUserDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)trashPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kTrashFolderType forDomain:kUserDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)trashPathForDesc:(NTFileDesc*)desc create:(BOOL)create;
{	
	return [self findSystemFolderType:kTrashFolderType forDomain:[desc volumeRefNum] createFolder:create];
}

- (NSString*)userLibraryPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kDomainLibraryFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userContextualMenuItemsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kContextualMenuItemsFolderType forDomain:kUserDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)contextualMenuItemsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kContextualMenuItemsFolderType forDomain:kLocalDomain  createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userApplicationsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kApplicationsFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)desktopPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kDesktopFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)documentsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kDocumentsFolderType forDomain:kUserDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)musicPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kMusicDocumentsFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)moviesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kMovieDocumentsFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)picturesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kPictureDocumentsFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)sitesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kInternetSitesFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)publicPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kPublicFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userLogsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kLogsFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)recentServersPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kRecentServersFolderType forDomain:kUserDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)desktopPicturesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kDesktopPicturesFolderType forDomain:kLocalDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)computerPath;
{    
    return @"";
}

- (NSString*)rootPath;
{
    return @"/";
}

- (NSString*)systemPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kSystemFolderType forDomain:kLocalDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)usersPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kUsersFolderType forDomain:kLocalDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)libraryPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kDomainLibraryFolderType forDomain:kLocalDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)applicationsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kApplicationsFolderType forDomain:kLocalDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

//---------------------------------------------------------- 
//  utilitiesPath 
//---------------------------------------------------------- 
- (NSString *)utilitiesPath
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kUtilitiesFolderType forDomain:kLocalDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)classicApplicationsPath;
{
    return @"/Applications (Mac OS 9)";
}

- (NSString*)developerApplicationsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		// kLocalDomain returned nil
		result = [self findSystemFolderType:kDeveloperApplicationsFolderType forDomain:kSystemDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)networkApplicationsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kApplicationsFolderType forDomain:kNetworkDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)tmpPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = NSTemporaryDirectory();
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)varlogPath;
{
    return @"/var/log";
}

- (NSString*)logsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kLogsFolderType forDomain:kLocalDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)consoleLogsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self logsPath] stringByAppendingPathComponent:@"Console"];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)preferencePanesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kPreferencePanesFolderType forDomain:kLocalDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)systemPreferencePanesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kPreferencePanesFolderType forDomain:kLocalDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userPreferencePanesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kPreferencePanesFolderType forDomain:kUserDomain createFolder:NO];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userApplicationSupportPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kApplicationSupportFolderType forDomain:kUserDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userApplicationSupportApplicationPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self userApplicationSupportPath] stringByAppendingPathComponent:[NTUtilities applicationName]];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)applicationSupportPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kApplicationSupportFolderType forDomain:kLocalDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)applicationSupportApplicationPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self applicationSupportPath] stringByAppendingPathComponent:[NTUtilities applicationName]];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userPreferencesPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [self findSystemFolderType:kPreferencesFolderType forDomain:kUserDomain createFolder:YES];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userApplicationSupportPluginsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self userApplicationSupportApplicationPath] stringByAppendingPathComponent:kPluginsFolderName];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userApplicationSupportSettingsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self userApplicationSupportApplicationPath] stringByAppendingPathComponent:kSettingsFolderName];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userApplicationSupportCoreDataPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self userApplicationSupportApplicationPath] stringByAppendingPathComponent:kCoreDataFolderName];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)applicationSupportPluginsPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self applicationSupportApplicationPath] stringByAppendingPathComponent:kPluginsFolderName];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userApplicationSupportPluginSupportPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self userApplicationSupportApplicationPath] stringByAppendingPathComponent:@"PlugIn Support"];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)userInputManagersPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self userLibraryPath] stringByAppendingPathComponent:@"InputManagers"];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

// overridden to lazily create
- (NSString *)savedSearchesPath
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self userLibraryPath] stringByAppendingPathComponent:@"Saved Searches"];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}
	
//---------------------------------------------------------- 
//  downloadsPath 
//---------------------------------------------------------- 
- (NSString *)downloadsPath
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self homePath] stringByAppendingPathComponent:@"Downloads"];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

- (NSString*)inputManagersPath;
{
	NSString* result = nil;
	NSString* theKey = NSStringFromSelector(_cmd);
	
	result = [self pathForKey:theKey];	
	if (!result)
	{	
		result = [[self libraryPath] stringByAppendingPathComponent:@"InputManagers"];
		
		// create folder if doesn't exist
        if (![NTPathUtilities pathOK:result])
            [NTFileCreation makeFolder:result permissions:0];
		
		[self setPath:result forKey:theKey];
    }
	
	return result;
}

// =============================================================================

- (NTFileDesc*)favorites
{
    return [NTFileDesc descResolve:[self favoritesPath]];
}

- (NTFileDesc*)userLibrary;
{
    return [NTFileDesc descResolve:[self userLibraryPath]];
}

- (NTFileDesc*)contextualMenuItems;
{
    return [NTFileDesc descResolve:[self contextualMenuItemsPath]];
}

- (NTFileDesc*)userContextualMenuItems;
{
    return [NTFileDesc descResolve:[self userContextualMenuItemsPath]];
}

- (NTFileDesc*)trash
{
    return [NTFileDesc descResolve:[self trashPath]];
}

- (NTFileDesc*)root
{
    return [NTFileDesc descResolve:[self rootPath]];
}

- (NTFileDesc*)library;
{
    return [NTFileDesc descResolve:[self libraryPath]];
}

- (NTFileDesc*)users;
{
    return [NTFileDesc descResolve:[self usersPath]];
}

- (NTFileDesc*)system;
{
    return [NTFileDesc descResolve:[self systemPath]];
}

- (NTFileDesc*)home
{
    return [NTFileDesc descResolve:[self homePath]];
}

- (NTFileDesc*)applications
{
    return [NTFileDesc descResolve:[self applicationsPath]];
}

- (NTFileDesc*)utilities;
{
	return [NTFileDesc descResolve:[self utilitiesPath]];
}

- (NTFileDesc*)classicApplications
{
    return [NTFileDesc descResolve:[self classicApplicationsPath]];
}

- (NTFileDesc*)developerApplications
{
    return [NTFileDesc descResolve:[self developerApplicationsPath]];
}

- (NTFileDesc*)networkApplications
{
    return [NTFileDesc descResolve:[self networkApplicationsPath]];
}

- (NTFileDesc*)userApplications
{
    return [NTFileDesc descResolve:[self userApplicationsPath]];
}

- (NTFileDesc*)desktop
{
    return [NTFileDesc descResolve:[self desktopPath]];
}

- (NTFileDesc*)documents
{
    return [NTFileDesc descResolve:[self documentsPath]];
}

- (NTFileDesc*)music
{
    return [NTFileDesc descResolve:[self musicPath]];
}

- (NTFileDesc*)movies
{
    return [NTFileDesc descResolve:[self moviesPath]];
}

- (NTFileDesc*)pictures
{
    return [NTFileDesc descResolve:[self picturesPath]];
}

- (NTFileDesc*)sites
{
    return [NTFileDesc descResolve:[self sitesPath]];
}

- (NTFileDesc*)public
{
    return [NTFileDesc descResolve:[self publicPath]];
}

- (NTFileDesc*)recentServers;
{
    return [NTFileDesc descResolve:[self recentServersPath]];
}

- (NTFileDesc*)desktopPictures;
{
	return [NTFileDesc descResolve:[self desktopPicturesPath]];
}

- (NTFileDesc*)computer
{
    return [NTFileDesc descNoResolve:[self computerPath]];
}

- (NTFileDesc*)tmp;
{
    return [NTFileDesc descResolve:[self tmpPath]];
}

- (NTFileDesc*)varlog;
{
    return [NTFileDesc descResolve:[self varlogPath]];
}

- (NTFileDesc*)logs;
{
    return [NTFileDesc descResolve:[self logsPath]];
}

- (NTFileDesc *)savedSearches;
{
	return [NTFileDesc descResolve:[self savedSearchesPath]];
}

- (NTFileDesc*)userLogs;
{
	return [NTFileDesc descResolve:[self userLogsPath]];
}

- (NSArray*)applicationDirectories;
{
	@synchronized(self) {
		if (!self.applicationDirectories_storage)
		{
			NSMutableArray *result = [NSMutableArray array];
			NTFileDesc *folder;
			
			folder = [self applications];
			if ([folder isValid] && [folder isDirectory] && ![folder isPackage] && ![folder isInvisible])
				[result addObject:folder];
			folder = [self userApplications];
			if ([folder isValid] && [folder isDirectory] && ![folder isPackage] && ![folder isInvisible])
				[result addObject:folder];
			folder = [self classicApplications];
			if ([folder isValid] && [folder isDirectory] && ![folder isPackage] && ![folder isInvisible])
				[result addObject:folder];
			folder = [self developerApplications];
			if ([folder isValid] && [folder isDirectory] && ![folder isPackage] && ![folder isInvisible])
				[result addObject:folder];
			folder = [self networkApplications];
			if ([folder isValid] && [folder isDirectory] && ![folder isPackage] && ![folder isInvisible])
				[result addObject:folder];
			
			self.applicationDirectories_storage = [NSArray arrayWithArray:result];
		}	
	}
	
	return self.applicationDirectories_storage;
}

- (NTFileDesc*)consoleLogs;
{
    return [NTFileDesc descResolve:[self consoleLogsPath]];
}

- (NTFileDesc*)preferencePanes;
{
    return [NTFileDesc descResolve:[self preferencePanesPath]];
}

- (NTFileDesc*)systemPreferencePanes;
{
    return [NTFileDesc descResolve:[self systemPreferencePanesPath]];
}

- (NTFileDesc*)userPreferencePanes
{
    return [NTFileDesc descResolve:[self userPreferencePanesPath]];
}

- (NTFileDesc*)userApplicationSupport;
{
    return [NTFileDesc descResolve:[self userApplicationSupportPath]];
}

- (NTFileDesc*)userApplicationSupportApplication;
{
    return [NTFileDesc descResolve:[self userApplicationSupportApplicationPath]];
}

- (NTFileDesc*)userApplicationSupportPlugins;
{
    return [NTFileDesc descResolve:[self userApplicationSupportPluginsPath]];
}

- (NTFileDesc*)applicationSupport;
{
    return [NTFileDesc descResolve:[self applicationSupportPath]];
}

- (NTFileDesc*)applicationSupportApplication;
{
    return [NTFileDesc descResolve:[self applicationSupportApplicationPath]];
}

- (NTFileDesc*)userApplicationSupportPluginSupport;  // only exists for user, not global
{
	return [NTFileDesc descResolve:[self userApplicationSupportPluginSupportPath]];
}

- (NTFileDesc*)userApplicationSupportSettings;  // only exists for user, not global
{
	return [NTFileDesc descResolve:[self userApplicationSupportSettingsPath]];
}

- (NTFileDesc*)userApplicationSupportCoreData;
{
	return [NTFileDesc descResolve:[self userApplicationSupportCoreDataPath]];
}

- (NTFileDesc*)applicationSupportPlugins;
{
    return [NTFileDesc descResolve:[self applicationSupportPluginsPath]];
}

- (NTFileDesc*)userPreferences;
{
    return [NTFileDesc descResolve:[self userPreferencesPath]];
}

- (NTFileDesc*)userInputManagers;
{
    return [NTFileDesc descResolve:[self userInputManagersPath]];
}

- (NTFileDesc*)inputManagers;
{
    return [NTFileDesc descResolve:[self inputManagersPath]];
}

- (NTFileDesc*)downloads;
{
    return [NTFileDesc descResolve:[self downloadsPath]];
}

- (NTFileDesc*)trashForDesc:(NTFileDesc*)desc create:(BOOL)create;
{
	NTFileDesc *trashDesc = nil;
	
	// made static for speed
	static NTFileDesc *homeDesc=nil;
	if (!homeDesc)
		homeDesc = [[self home] retain];
	
	// is this on a different volume than the home folder?
	if ([desc volumeRefNum] != [homeDesc volumeRefNum])
	{
		// network volumes dont have trash cans, but if home is a remote home, then it's OK
		if (![desc isNetwork] && ![desc isVolumeReadOnly])
			trashDesc = [NTFileDesc descResolve:[self trashPathForDesc:desc create:create]];
	}
	else
		trashDesc = [self trash];
	
	return trashDesc;
}

@end

@implementation NTDefaultDirectory (Private)

- (NSString *)findSystemFolderType:(int)folderType forDomain:(int)domain createFolder:(BOOL)createFolder;
{
    FSRef fsRef;
    NSString *result = nil;

    OSErr err = FSFindFolder(domain, folderType, createFolder, &fsRef);
    if (!err)
    {
		NTFileDesc* desc = [NTFileDesc descFSRef:&fsRef];
		
		if ([desc isValid])
			result = [desc path];
    }

    return result;
}

- (NSString*)pathForKey:(NSString*)theKey;
{
	NSString* result = nil;
	
	@synchronized(self) {
		result = [[[self.paths objectForKey:theKey] retain] autorelease];
	}
	
	return result;
}

- (void)setPath:(NSString*)thePath forKey:(NSString*)theKey;
{
	@synchronized(self) {
		[self.paths setObjectIf:thePath forKey:theKey];
	}
}	

@end

