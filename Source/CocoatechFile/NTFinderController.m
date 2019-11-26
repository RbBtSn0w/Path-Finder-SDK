//
//  NTFinderController.m
//  Path Finder
//
//  Created by Steve Gehrman on 6/27/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTFinderController.h"
#import "NTRunningAppManager.h"
#import "NTLaunchServices.h"
#import "NTAuthOpen.h"

/*
 1. Click "finder-quit" line and press "Add Item" button.
 2. Click on the new line "Item 1", change the type to "Dictionary" and press "Add Child" button two times to make two new items inside "Item 1".
 2b. Change the type of the first new-made item to "Number". Change the "name" to "command" and "value" — "1004".
 3. Change the "name" of the second item to "name" and "value" to "REMOVE_FROM_DOCK".
 4. Repeat steps 2 through 4 with "finder-running" instead of "finder-quit" which will remove the Finder from the dock and the command-tab application launcher while still letting you open and use Finder windows
 5. Press cmd+S to Save .plist, authorise as root and quit the plist editor.
 6. Open "Activity Monitor" (located in /Applications/Utilities), find Dock process and force quit it. It will relaunch automaticly in few seconds.
 7. In Path Finder "General" preferences check "Quit the Finder automaticly at launch". If Finder is launched, open PathFinder main menu and press "Quit Finder" to kill it.
 8. Control + click of Finder icon and press the new button "Remove from Dock"
 */

#define kFinderQuitKey @"finder-quit"
#define kFinderRunningKey @"finder-running"

@interface NTFinderController ()
@property (nonatomic, retain) NSBundle *dockBundle;
@property (nonatomic, retain) NTFileDesc *plistFile;
@property (nonatomic, retain) id notificationObject;
@property (nonatomic, retain) NSNumber *cachedIsDockHackInstalled;
@property (nonatomic, retain) NSString *fndrPath;
@end

@interface NTFinderController (Private)
- (NSMutableDictionary*)plistAsDictionary;
- (void)relaunchDock;
- (BOOL)hackHasBeenSetInDictionary:(NSMutableDictionary*)theDict;
- (NSMutableDictionary*)commandDictionary;
- (void)saveUpdatedDictionary:(NSMutableDictionary*)theDict;
- (void)updateCachedIsDockInstalled:(NSMutableDictionary*)theDict;
@end

@implementation NTFinderController

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize dockBundle;
@synthesize plistFile;
@synthesize notificationObject;
@synthesize cachedIsDockHackInstalled;
@synthesize fndrPath;

- (id)init;
{
	self = [super init];

	self.dockBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"Dock"]];
	self.plistFile = [NTFileDesc descResolve:[self.dockBundle pathForResource:@"DockMenus" ofType:@"plist"]];

	return self;
}

- (void)dealloc
{
    self.dockBundle = nil;
    self.plistFile = nil;
	self.notificationObject = nil;
	self.cachedIsDockHackInstalled = nil;
    self.fndrPath = nil;

    [super dealloc];
}

- (NSString*)finderPath;
{
	NSString* result = nil;
	
	// called from thread, so make sure thread safe
	@synchronized(self) {
		if (!self.fndrPath)
			self.fndrPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Finder"];
	
		result = self.fndrPath;
	}
	
	return result;
}

- (void)quitFinder;
{
	[[NTRM applicationWithBundleIdentifier:kFinderBundleIdentifier] terminate];
}

- (void)openFinder;
{
	NSString* thePath = [self finderPath];
	
	if (thePath)
		[NTLaunchServices launchDescs:nil withApp:thePath launchFlags:kLSLaunchDefaults | kLSLaunchDontSwitch];
}

- (BOOL)isFinderRunning;
{
	NSRunningApplication* finder = [NTRM applicationWithBundleIdentifier:kFinderBundleIdentifier];
	
	if (finder)
		return !finder.isTerminated;

	return NO;	
}

- (void)relaunchFinder;
{
	[NTRM relaunch:[NTRM applicationWithBundleIdentifier:kFinderBundleIdentifier]];
}

- (void)toggleFinder;
{
	if ([self isFinderRunning])
		[self quitFinder];
	else 
		[self openFinder];
}

- (BOOL)isDockHackInstalled;
{
	if (!self.cachedIsDockHackInstalled)
	{
		NSMutableDictionary* theDict = [self plistAsDictionary];
		
		[self updateCachedIsDockInstalled:theDict];
	}
	
	return [self.cachedIsDockHackInstalled boolValue];
}

- (void)toggleDockHack;
{
	NSMutableDictionary* theDict = [self plistAsDictionary];
	if (theDict)
	{		
		NSMutableArray *finderQuitArray = [theDict objectForKey:kFinderQuitKey];
		NSMutableArray *finderRunningArray = [theDict objectForKey:kFinderRunningKey];
		
		// toggle the hack
		if (![self hackHasBeenSetInDictionary:theDict])
		{					
			// not sure if there is any problem with setting one dictionary in two places, so to be clear, I copy/autorelease it
			[finderQuitArray addObject:[self commandDictionary]];
			[finderRunningArray addObject:[self commandDictionary]];
			
			[self saveUpdatedDictionary:theDict];
		}
		else 
		{
			NSMutableDictionary* theCmdDict = [self commandDictionary];
			
			// remove from finderQuitArray
			for (NSMutableDictionary* subDict in finderQuitArray)
			{
				if ([subDict isEqualToDictionary:theCmdDict])
				{
					[finderQuitArray removeObject:subDict];
					break;
				}
			}
			
			// remove from finderRunningArray
			for (NSMutableDictionary* subDict in finderRunningArray)
			{
				if ([subDict isEqualToDictionary:theCmdDict])
				{
					[finderRunningArray removeObject:subDict];
					break;
				}
			}
			
			[self saveUpdatedDictionary:theDict];
		}
	}
}

- (void)toggleFindersDesktopEnabled;
{
	[self setFindersDesktopEnabled:![self findersDesktopEnabled]];
}

- (BOOL)findersDesktopEnabled;
{
	return [[NTGlobalPreferences sharedInstance] finderDesktopEnabled];
}

- (void)setFindersDesktopEnabled:(BOOL)isEnabled;
{	
	if ([[NTGlobalPreferences sharedInstance] setFinderDesktopEnabled:isEnabled])		
	{
		// only ask if finder running
		if ([[NTFinderController sharedInstance] isFinderRunning])
		{
			[NTAlertPanel show:NSInformationalAlertStyle
						target:self 
					  selector:@selector(sheetDone:)
						 title:[NTLocalizedString localize:@"The Finder must be relaunched for this change to take effect." table:@"preferencesUI"]
					   message:[NTLocalizedString localize:@"If you do not relaunch the Finder now the change will be applied the next time you log out and back in." table:@"preferencesUI"]
					   context:nil 
						window:nil
			defaultButtonTitle:[NTLocalizedString localize:@"Relaunch Finder" table:@"preferencesUI"]
		  alternateButtonTitle:[NTLocalizedString localize:@"Cancel"]];
		}
	}
}

@end

@implementation NTFinderController (Private)

// called from NTAlertPanel in setFindersDesktopHidden
- (void)sheetDone:(id)sender;
{
    NTAlertPanel* panel = (NTAlertPanel*)sender;
    
    if ([panel resultCode] == NSAlertFirstButtonReturn)
		[[NTFinderController sharedInstance] relaunchFinder];
}

- (void)updateCachedIsDockInstalled:(NSMutableDictionary*)theDict;
{
	self.cachedIsDockHackInstalled = nil;
	
	if (theDict)
	{
		if ([self hackHasBeenSetInDictionary:theDict])
			self.cachedIsDockHackInstalled = [NSNumber numberWithBool:YES];
		else
			self.cachedIsDockHackInstalled = [NSNumber numberWithBool:NO];
	}
}	

- (NSMutableDictionary*)plistAsDictionary;
{
	if (self.plistFile && self.dockBundle)
	{		
		// not sure which is better
		NSMutableDictionary* dict=nil;
		if (NO)
			dict = [NSMutableDictionary dictionaryWithContentsOfURL:[self.plistFile URL]];
		else
		{
			NSPropertyListFormat outFormat;
			NSString* errorString;
			
			errorString=nil;
			dict = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfURL:[self.plistFile URL]] mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&outFormat errorDescription:&errorString];
			
			if (!dict)
				NSLog(@"%@:%@", NSStringFromSelector(_cmd), errorString);
		}
		
		return dict;
	}
	
	return nil;
}	

- (void)saveUpdatedDictionary:(NSMutableDictionary*)theDict;
{
	// update the cache, passing nil to clear it first.  The user could enter a wrong password or cancel authorization
	[self updateCachedIsDockInstalled:nil];

	// convert to plist data
	NSString* errorString = nil;
	NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:theDict
																   format:NSPropertyListXMLFormat_v1_0
														 errorDescription:&errorString];
	
	// write data
	if (!plistData) 
		NSLog(@"%@", errorString);			
	else
	{				
		if ([self.plistFile isWritable])
		{
			NSError *theError;
			BOOL res = [plistData writeToURL:[self.plistFile URL] options:NSAtomicWrite error:&theError];
			
			if (!res)
				NSLog(@"Error: %@", theError);
			else
			{
				[self relaunchDock];
			
				// update the cache just to save a bit of time
				[self updateCachedIsDockInstalled:theDict];
			}
		}
		else
		{			
			self.notificationObject = [NTAuthOpen writeData:plistData toFile:self.plistFile];
			
			// register for the authOpen notification
			[NTAuthOpen observe:self selector:@selector(authOpenRelaunchDockNotification:) object:self.notificationObject];		
		}
	}
}

- (void)authOpenRelaunchDockNotification:(NSNotification*)theNotification;
{	
	id theObject = [theNotification object];
	
	if (theObject == self.notificationObject)
	{		
		// unregister for the authOpen notification
		[NTAuthOpen remove:self object:self.notificationObject];
		self.notificationObject = nil;
		
		[self relaunchDock];
	}
}

- (void)relaunchDock;
{
	// relaunch Dock
	NSRunningApplication* dockProcess = [NTRM applicationWithURL:[self.dockBundle bundleURL]];
	
	if (dockProcess)
		[dockProcess terminate];  // relaunches itself
}

- (BOOL)hackHasBeenSetInDictionary:(NSMutableDictionary*)theDict;
{
	NSMutableArray *finderQuitArray = [theDict objectForKey:kFinderQuitKey];
	NSMutableArray *finderRunningArray = [theDict objectForKey:kFinderRunningKey];
	NSMutableDictionary* theCmdDict = [self commandDictionary];
	
	// check finderQuitArray
	for (NSMutableDictionary* subDict in finderQuitArray)
	{
		if ([subDict isEqualToDictionary:theCmdDict])
			return YES;
	}
	
	// check finderRunningArray
	for (NSMutableDictionary* subDict in finderRunningArray)
	{
		if ([subDict isEqualToDictionary:theCmdDict])
			return YES;
	}

	return NO;
}

- (NSMutableDictionary*)commandDictionary;
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1004], @"command", @"REMOVE_FROM_DOCK", @"name", nil];
}

@end
