//
//  NTFileEnvironment.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFileEnvironment.h"

@interface NTFileEnvironment ()
@property (nonatomic, assign) NSInteger disableCacheFlag;
@end

@implementation NTFileEnvironment

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize logKQueueEvents;
@synthesize logBonjourEvents;
@synthesize logGeneralEvents;
@synthesize logDirectoryLists;
@synthesize logFSEvents, disableCacheFlag;

// set to yet to check for mem leaks
- (BOOL)disableCache;
{
	if (self.disableCacheFlag == 0)  // default state, unset
	{
		self.disableCacheFlag = -1;  // -1 is NO, 1 is YES
		
		char * env = getenv("DEBUG_DISABLECACHE");
		
		if (env && strlen(env))
		{
			NSString* s = [NSString stringWithUTF8String:env];
			
			if ([s isEqualToStringCaseInsensitive:@"YES"] || [s isEqualToString:@"1"])
				self.disableCacheFlag = 1;
		}
	}
	
	return (self.disableCacheFlag == 1);
}

- (void)notify_FSEvent:(NSString*)eventType eventInfo:(NSString*)eventInfo;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNTFSEventLogNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"FSEVENT(%@): %@", eventType, eventInfo] forKey:@"info"]];
}

- (void)notify_DirectoryList:(NSString*)thePath list:(NSArray*)theList state:(NSString*)theState;
{
	NSMutableString* info = [NSMutableString stringWithCapacity:500];
	
	[info appendFormat:@"DIRLIST(%@, %d) %@\n",theState, [theList count], thePath];
	for (NTFileDesc* desc in theList)
		[info appendFormat:@"    %@\n", [desc displayName]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNTDirectoryLogNotification object:nil userInfo:[NSDictionary dictionaryWithObject:info forKey:@"info"]];
}

- (void)notify_KQueueEvent:(NSString*)eventInfo;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNTKqueueLogNotification object:nil userInfo:[NSDictionary dictionaryWithObject:eventInfo forKey:@"info"]];
}

- (void)notify_BonjourEvent:(NSString*)eventInfo;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNTBonjourLogNotification object:nil userInfo:[NSDictionary dictionaryWithObject:eventInfo forKey:@"info"]];
}

- (void)notify_GeneralEvent:(NSString*)eventInfo;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kNTGeneralLogNotification object:nil userInfo:[NSDictionary dictionaryWithObject:eventInfo forKey:@"info"]];
}

@end
