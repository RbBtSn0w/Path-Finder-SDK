//
//  NTFSEventClient.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/23/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTFSEventClient.h"
#import "NTFileSystemEventCenter.h"
#import "NTVolume.h"
#import "NTVolumeMgrState.h"
#import "NTFileSystemEventMessage.h"
#import "NTFileSystemEventCenterClient.h"

@interface NTFSEventClient ()
@property (nonatomic, retain) NTFileSystemEventCenterClient *eventCenterClient;
@property (nonatomic, retain) NSNumber *uniqueID;
@end

@implementation NTFSEventClient

@synthesize eventCenterClient;
@synthesize uniqueID;

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
	if (self.eventCenterClient)
		[[NTFileSystemEventCenter sharedInstance] removeEventClient:self.eventCenterClient];

	self.uniqueID = nil;
    self.eventCenterClient = nil;
    [super dealloc];
}

+ (NTFSEventClient*)client:(NTMessageProxy*)theDelegateProxy folder:(NTFileDesc*)theFolder;
{
	return [self client:theDelegateProxy folder:theFolder includeSubfolders:NO];
}

+ (NTFSEventClient*)client:(NTMessageProxy*)theDelegateProxy folder:(NTFileDesc*)theFolder includeSubfolders:(BOOL)includeSubfolders;
{
	NTFSEventClient* result = [[NTFSEventClient alloc] init];
	
	result.uniqueID = [NSNumber unique];
	result.eventCenterClient = [NTFileSystemEventCenterClient client:theDelegateProxy folder:theFolder includeSubfolders:includeSubfolders uniqueID:result.uniqueID];
	
	if (result.eventCenterClient)
	{
		// adding the client will call our initializeValues routine so it happens in a thread to avoid any slowdown with a disk hit
		[[NTFileSystemEventCenter sharedInstance] addEventClient:result.eventCenterClient];
	}
	
	return [result autorelease];
}

- (NTFileDesc*)folder;
{
	return self.eventCenterClient.folder;
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]), [self.eventCenterClient.folder path]];
}

+ (void)manuallyRefreshDirectory:(NTFileDesc*)directory;
{
	if ([directory isComputer])
	{
		[NTVolumeMgrState incrementBuild];  // must increment build number to create new NTFileDescs, otherwise you'll get the same as previous list
		
		[[NTFileSystemEventCenter sharedInstance] manuallyNotifyClientsForPath:nil];
	}
	else
	{
		NSString* thePath = [directory path];
		
		if (thePath)
			[[NTFileSystemEventCenter sharedInstance] manuallyNotifyClientsForPath:thePath];
	}	
}

@end
