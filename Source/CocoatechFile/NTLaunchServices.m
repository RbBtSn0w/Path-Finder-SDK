//
//  NTLaunchServices.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Wed Mar 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NTLaunchServices.h"
#import "NTDefaultDirectory.h"
#import "NTProcess.h"

static OSStatus NTLaunchServicesEventHandler(EventHandlerCallRef nextHandler, EventRef inEvent, void* inRefcon);
DEFINE_ONE_SHOT_HANDLER_GETTER(NTLaunchServicesEventHandler) 

@interface NTLaunchServices (Private)
+ (NSArray*)cleanOpenWithArray:(NSArray*)descs;
+ (NTFileDesc*)bestApplicationInArray:(NSArray*)array;
+ (NSArray*)allApplicationURLs;
+ (void)installApplicationEventHandler;
@end

static NSUInteger kNTLaunchServicesRefConFlag = 0x23324255;

// undocumented function call
extern OSStatus _LSCopyAllApplicationURLs(CFArrayRef * outURLs);

@implementation NTLaunchServices

+ (BOOL)printDescs:(NSArray*)descs;
{
	BOOL success = NO;
	
	// get just the files and packages
	// are their any files or packages in this list?  If not, return NO
	descs = [NTFileDesc descsToFilesAndFolders:descs
									outFolders:nil
						treatPackagesAsFolders:NO];
	
	if ([descs count])
	{		
		NSArray* itemURLs = [NTFileDesc descsToURLs:descs];
		
		if ([itemURLs count])
		{
			success = YES;
						
			LSLaunchURLSpec lspec;
			lspec.appURL = NULL;
			lspec.itemURLs = (CFArrayRef) itemURLs;
			lspec.passThruParams = NULL;
			lspec.launchFlags = kLSLaunchDefaults | kLSLaunchAndPrint;
			lspec.asyncRefCon = 0;
			
			OSStatus err = LSOpenFromURLSpec(&lspec, NULL);
			if (err)
			{
				success = NO;
				NSLog(@"LSOpenFromURLSpec err: %d", err);
			}
		}
	}
	
    return success;
}

+ (BOOL)launchDescs:(NSArray*)descs withApp:(NSString*)appPath;
{
    return [self launchDescs:descs withApp:appPath launchFlags:kLSLaunchDefaults];
}

// returns YES if all succeed
+ (BOOL)launchDescs:(NSArray*)descs withApp:(NSString*)appPath launchFlags:(LSLaunchFlags)launchFlags;
{
    BOOL success = NO;
	NSArray* itemURLs = [NTFileDesc descsToURLs:descs];
	
	// we sometimes just launch an app with no documents 
	if ([itemURLs count] || appPath)
	{
		NSURL *appURL = nil;
		
		success = YES;

		[self installApplicationEventHandler];

		if ([appPath length])
			appURL = [NSURL fileURLWithPath:appPath];
		
		LSLaunchURLSpec lspec;
		lspec.appURL = (CFURLRef) appURL;
		lspec.itemURLs = (CFArrayRef) itemURLs;
		lspec.passThruParams = NULL;
		lspec.launchFlags = launchFlags;
		lspec.asyncRefCon = (void*)kNTLaunchServicesRefConFlag;
		
		OSStatus err = LSOpenFromURLSpec(&lspec, NULL);
		if (err)
		{
			success = NO;
			NSLog(@"LSOpenFromURLSpec err: %d", err);
		}
	}
	
    return success;
}

	// get a list of apps that can open a document
	// NOTE: this searches network volumes!!
+ (NSArray*)applicationURLsForItem:(NTFileDesc*)inDesc;
{
    CFArrayRef outURLs;
    NSMutableArray* result=nil;
	
    outURLs = LSCopyApplicationURLsForURL((CFURLRef)[inDesc URL], kLSRolesAll);
    if (outURLs)
    {
        if ([(id)outURLs isKindOfClass:[NSArray class]])
        {
            result = [NSMutableArray arrayWithArray:(NSArray*)outURLs];
            
            // filter out .exe files
            int i, cnt = [result count];
            NSURL *url;
            
            for (i=(cnt-1);i>=0;i--)
            {
                url = [result objectAtIndex:i];
                
                if ([[[url path] pathExtension] isEqualToStringCaseInsensitive:@"exe"])
                    [result removeObjectAtIndex:i];
            }   
		}
        
        CFRelease(outURLs);
    }
	
    return [self cleanOpenWithArray:[NTFileDesc urlsToDescs:result]];
}

+ (NSArray*)applications;
{
	NSArray *urls = [self allApplicationURLs];
	
	return [self cleanOpenWithArray:[NTFileDesc urlsToDescs:urls]];
}

@end

@implementation NTLaunchServices (Private)

+ (NSArray*)cleanOpenWithArray:(NSArray*)descs;
{
    NSMutableArray* results = [NSMutableArray arrayWithCapacity:[descs count]];
    NTFileDesc *desc;
	NSEnumerator *enumerator;
	
	// first create a dictionary based on displayName of all the apps	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[descs count]];
	NSMutableArray* matchArray;
	
	for (desc in descs)
	{
		matchArray = [dict objectForKey:[desc displayName]];
		
		if (!matchArray)
			[dict setObject:[NSMutableArray arrayWithObject:desc] forKey:[desc displayName]];
		else
			[matchArray addObject:desc];
	}
	
	// then examine the directory items with more than one hit per displayName
	enumerator = [dict objectEnumerator];
	while (matchArray = [enumerator nextObject])
	{
		if ([matchArray count] > 1)
			desc = [self bestApplicationInArray:matchArray];
		else
			desc = [matchArray objectAtIndex:0];
		
        if ([desc isValid] && ![desc isNetwork])
			[results addObject:desc];
	}
	
    return results;
}

+ (NTFileDesc*)bestApplicationInArray:(NSArray*)array;
{
	// make sure the file is a child of one of the standard application directories
	NSArray* appDirs = [[NTDefaultDirectory sharedInstance] applicationDirectories];
	NTFileDesc *appDir;
	
	NTFileDesc *desc;
	NTFileDesc* firstMatch=nil;
	
	for (desc in array)
	{
		if ([desc isValid] && ![desc isNetwork])
		{			
			if (!firstMatch)
				firstMatch = desc;
			
			for (appDir in appDirs)
			{
				if ([appDir isParentOfDesc:desc])
					return desc;
			}
		}
	}

	if (!firstMatch)
		firstMatch = [array objectAtIndex:0];
	
	return firstMatch;
}

+ (NSArray*)allApplicationURLs;
{
    OSStatus err;
    NSArray* result=nil;
    CFArrayRef outURLs;
	
    // undocumented function call
    err = _LSCopyAllApplicationURLs(&outURLs);
    if (!err)
    {
        if ([(id)outURLs isKindOfClass:[NSArray class]])
            result = [NSArray arrayWithArray:(NSArray*)outURLs];
		
        CFRelease(outURLs);
    }
	
    return result;
}

+ (void)installApplicationEventHandler;
{	
	// only set once
	static BOOL installed = NO;
	if (installed)
		return;
	installed = YES;
	
	const EventTypeSpec eventSpec[] = { 
		{ kEventClassApplication, kEventAppLaunchNotification },	
	};
	
	OSStatus err = InstallApplicationEventHandler(GetNTLaunchServicesEventHandlerUPP(),
												  GetEventTypeCount(eventSpec), eventSpec,
												  NULL, NULL);
		
	if (err)
		NSLog(@"InstallWindowEventHandler failed");	
}			

@end

static OSStatus NTLaunchServicesEventHandler(EventHandlerCallRef nextHandler,
											  EventRef inEvent, 
											  void* inRefcon)
{
    OSStatus result = eventNotHandledErr;
	
	switch (GetEventClass(inEvent))
	{
		case kEventClassApplication:
		{				
			switch (GetEventKind(inEvent))
			{
				case kEventAppLaunchNotification:
				{
					void *theRefCon;
					if (GetEventParameter(inEvent, kEventParamLaunchRefCon, typeRefCon, NULL, sizeof(void*), NULL, &theRefCon) == noErr)
					{
						if ((NSUInteger)theRefCon == kNTLaunchServicesRefConFlag)
						{
							ProcessSerialNumber psn;
							
							if (GetEventParameter(inEvent, kEventParamProcessID, typeProcessSerialNumber, NULL, sizeof(psn), NULL, &psn) == noErr)
							{
								// make sure the app is frontmost.  But in OS 10.5 that is not bring app forward on launch
								NTProcess* process = [NTProcess processWithPSN:psn];
								
								if (![process isEqualToFront] && ![process isBackgroundOnly] && ![process isBackgroundOnlyWithUI])
									[process makeFront:NO unminimizeWindows:NO];
							}
						}
					}
				}
					break;
				default:
					break;
			}
		}
			break;
	}
	
	if (result == eventNotHandledErr)
		result = CallNextEventHandler (nextHandler, inEvent); 
	
	return result;
}

