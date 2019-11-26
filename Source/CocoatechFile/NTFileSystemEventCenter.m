//
//  NTFileSystemEventCenter.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/23/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTFileSystemEventCenter.h"
#import "NTFileSystemEventClientMgr.h"
#import "NTFileSystemEventMessage.h"
#import "NTFileSystemEventListener.h"
#import "NTVolume.h"
#import "NTFileSystemEventCenterClient.h"
#import "NTVolumeNotificationMgr.h"
#import "NTVolumeMgr.h"

@interface NTFileSystemEventCenter()
@property (nonatomic, retain) NSMutableDictionary *clientMgrs;
@property (nonatomic, retain) NTMessageProxy* messageProxy;
@property (nonatomic, retain) NTFileSystemEventListener *eventListener;
@property (nonatomic, retain) NSMutableDictionary *volumeIDMap;
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@end

@interface NTFileSystemEventCenter(Private)
- (void)notifyClientsForEvent:(NTFileSystemEventMessage*)theMessage;
- (NTFileSystemEventClientMgr*)clientMgrForVolumeID:(NSString*)volumeID;
- (NSString*)volumeUniqueIDForMountPoint:(NSString*)mountPoint;
@end

@interface NTFileSystemEventCenter(Protocols) <NTMessageProxyProtocol>
@end

@implementation NTFileSystemEventCenter

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize clientMgrs, dispatchQueue, eventListener, messageProxy, volumeIDMap;

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (self.dispatchQueue)
	{
		dispatch_release(self.dispatchQueue);
		self.dispatchQueue = nil;
	}
	
	self.clientMgrs = nil;
	
	[self.messageProxy invalidate];
	self.messageProxy = nil;
	self.eventListener = nil;
	self.volumeIDMap = nil;
	
    [super dealloc];
}

- (id)init;
{
	self = [super init];
	
	self.clientMgrs = [NSMutableDictionary dictionary];
	self.messageProxy = [NTMessageProxy proxy:self];
	self.dispatchQueue = dispatch_queue_create("com.cocoatech.NTFileSystemEventCenter", NULL);
	
	self.eventListener = [NTFileSystemEventListener eventListener:self.messageProxy dispatchQueue:self.dispatchQueue];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(volumeListChangedNotification:)
												 name:kNTVolumeMgrVolumeListHasChangedNotification
											   object:[NTVolumeNotificationMgr sharedInstance]];
	
	return self;
}

- (void)addEventClient:(NTFileSystemEventCenterClient*)theClient;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			// fills in the member variables while in the thread to avoid any main thread hit for getting file paths
			[theClient initializeValues];
			
			if (theClient.volumeUniqueID)
			{		
				NTFileSystemEventClientMgr* clientMgr = [self.clientMgrs objectForKey:theClient.volumeUniqueID];
				if (!clientMgr)
				{				
					clientMgr = [NTFileSystemEventClientMgr clientMgr:theClient.caseSensitive];
					[self.clientMgrs setObject:clientMgr forKey:theClient.volumeUniqueID];
				}
								
				if (clientMgr)
					[clientMgr addClient:theClient];
			}
		}
		@catch (NSException * e) {
			NSLog(@"addEventClient exception: %@", e);
		}
		@finally {
		}		
	});
}

- (void)removeEventClient:(NTFileSystemEventCenterClient*)theClient;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			
			if (theClient.volumeUniqueID)
			{
				NTFileSystemEventClientMgr* clientMgr = [self.clientMgrs objectForKey:theClient.volumeUniqueID];
				
				if (clientMgr)
				{
					[clientMgr removeClient:theClient];
					
					if ([clientMgr isEmpty])
						[self.clientMgrs removeObjectForKey:theClient.volumeUniqueID];
				}
			}
		}
		@catch (NSException * e) {
			NSLog(@"removeEventClient exception: %@", e);
		}
		@finally {
		}		
	});
}

// nil is passed for computer level
- (void)manuallyNotifyClientsForPath:(NSString*)thePath;
{
	dispatch_async(self.dispatchQueue, ^{
		@try {
			if (thePath)
				[self notifyClientsForEvent:[NTFileSystemEventMessage message:thePath rescanSubdirectories:NO]];
			else
				[self notifyClientsForEvent:nil];
		}
		@catch (NSException * e) {
			NSLog(@"manuallyNotifyClientsForPath exception: %@", e);
		}
		@finally {
		}		
	});
}

@end

@implementation NTFileSystemEventCenter(Protocols) 

// <NTMessageProxyProtocol>

// this is called on our dispatch queue
- (void)messageProxy:(NTMessageProxy*)theProxy message:(id)theMessage;
{
	@try {
		NSArray* theMessages = (NSArray*)theMessage;
		
		for (NTFileSystemEventMessage* inMessage in theMessages)
			[self notifyClientsForEvent:inMessage];
	}
	@catch (NSException * e) {
		NSLog(@"messageProxy exception: %@", e);
	}
	@finally {
	}		
}

@end

@implementation NTFileSystemEventCenter (Notifications)

- (void)volumeListChangedNotification:(NSNotification*)notification;
{	
	dispatch_async(self.dispatchQueue, ^{
		@try {
			// clearing this volumeIDMap. What if a user unmounts a disk, then mounts another volume with the same mountPoint?
			self.volumeIDMap = nil;
			
			[self notifyClientsForEvent:nil];
		}
		@catch (NSException * e) {
			NSLog(@"volumeListChangedNotification exception: %@", e);
		}
		@finally {
		}		
	});
}

@end

@implementation NTFileSystemEventCenter(Private)

- (NSString*)volumeUniqueIDForMountPoint:(NSString*)mountPoint;
{
	if (!self.volumeIDMap)
		self.volumeIDMap = [NSMutableDictionary dictionary];

	NSString* result = [[[self.volumeIDMap objectForKey:mountPoint] retain] autorelease];
	if (!result)
	{
		result = [NTFileSystemEventCenter volumeIDForMountPoint:mountPoint];
		
		if (result)
			[self.volumeIDMap setObject:result forKey:mountPoint];
	}
	
	return result;
}

- (NTFileSystemEventClientMgr*)clientMgrForVolumeID:(NSString*)volumeID;
{
	NTFileSystemEventClientMgr* clientMgr=nil;
	
	if (volumeID)
		clientMgr = [[[self.clientMgrs objectForKey:volumeID] retain] autorelease];
	
	return clientMgr;
}

- (void)notifyClientsForEvent:(NTFileSystemEventMessage*)theMessage;
{
	if (theMessage)
	{		
		NTFileSystemEventClientMgr* clientMgr = [self clientMgrForVolumeID:[self volumeUniqueIDForMountPoint:[theMessage mountPoint]]];
		if (clientMgr)
			[clientMgr notifyClientsWithEvent:theMessage notifyParent:YES];
	}
	else
	{
		// computer level
		NTFileSystemEventClientMgr* clientMgr = [self clientMgrForVolumeID:kNTComputerEventClient];
		if (clientMgr)
			[clientMgr notifyClientsWithEvent:nil notifyParent:NO];
	}
}

@end

@implementation NTFileSystemEventCenter(PathUtilities)

+ (NSString*)volumeIDForPath:(NSString*)thePath;
{
	NSString* outMountPoint=nil;
	
	[[NTVolumeMgr sharedInstance] relativePath:thePath outMountPoint:&outMountPoint];
	
	return [self volumeIDForMountPoint:outMountPoint];
}

+ (NSString*)volumeIDForMountPoint:(NSString*)mountPoint;
{
	NSString* result = @"????";  // being safe and not returning nil, not sure if it would ever happen
	
	if (mountPoint)
	{
		NTVolume* theVolume = [[NTFileDesc descNoResolve:mountPoint] volume];
		if (theVolume)
		{
			result = [theVolume volumeUniqueID];
			
			// for network volumes
			if (!result)
				result = [[theVolume volumeURL] absoluteString];
		}
	}
	
	return result;
}

@end


