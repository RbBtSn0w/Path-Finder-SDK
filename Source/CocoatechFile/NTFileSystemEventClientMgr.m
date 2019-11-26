//
//  NTFileSystemEventClientMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/23/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTFileSystemEventClientMgr.h"
#import "NTFileSystemEventCenterClient.h"
#import "NTFileSystemEventMessage.h"
#import "NTPathMonitor.h"

@interface NTFileSystemEventClientMgr()
@property (nonatomic, retain) NSMutableDictionary *clients;
@property (nonatomic, retain) NSMutableDictionary *subfolderClients;
@property (nonatomic, assign) BOOL caseSensitive;
@property (nonatomic, retain) NTPathMonitor *pathMonitor;
@property (nonatomic, retain) NSMutableDictionary* clientIDMap;

@property (nonatomic, retain) NSMutableArray *cachedPaths;
@property (nonatomic, retain) NSString *cachedMountPoint;
@end

@interface NTFileSystemEventClientMgr(Private)
- (NSArray*)clientsForRelativePath:(NSString*)theDictionaryKey;
- (void)doNotifySubfolderClientsWithRelativePath:(NSString*)theRelativePath message:(NTFileSystemEventMessage*)theMessage;
- (void)doNotifyClientsWithRelativePath:(NSString*)theRelativePath message:(NTFileSystemEventMessage*)theMessage;
- (NSArray*)subfolderClientsForRelativePath:(NSString*)theRelativePath;

- (void)processPathsAfterDelay;
@end

@implementation NTFileSystemEventClientMgr

@synthesize clients, subfolderClients, caseSensitive, pathMonitor, clientIDMap;
@synthesize cachedPaths;
@synthesize cachedMountPoint;

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
	self.clients = nil;
	self.subfolderClients = nil;
	self.pathMonitor = nil;
	self.clientIDMap = nil;
    self.cachedPaths = nil;
    self.cachedMountPoint = nil;
	
    [super dealloc];
}

+ (NTFileSystemEventClientMgr*)clientMgr:(BOOL)caseSensitive;
{
	NTFileSystemEventClientMgr* result = [[NTFileSystemEventClientMgr alloc] init];
	
	result.clients = [NSMutableDictionary dictionary];
	result.clientIDMap = [NSMutableDictionary dictionary];
	result.subfolderClients = [NSMutableDictionary dictionary];
	result.caseSensitive = caseSensitive;
	result.pathMonitor = [NTPathMonitor pathMonitor];
	
	return [result autorelease];
}

- (BOOL)isEmpty;
{	
	return ([self.clientIDMap count] == 0);
}

- (void)addClient:(NTFileSystemEventCenterClient*)theClient;
{
	if (theClient.comparePath)
	{		
		NSMutableDictionary *theClients = self.clients;
		if ([theClient includeSubfolders])
			theClients = self.subfolderClients;
		
		NSMutableArray* clientArray = [theClients objectForKey:theClient.comparePath];
		if (!clientArray)
		{
			clientArray = [NSMutableArray array];
			[theClients setObject:clientArray forKey:theClient.comparePath];
		}
		[clientArray addObject:theClient];

		[self.clientIDMap setObject:theClient forKey:theClient.uniqueID];
		
		// monitor path for renames
		if (!theClient.isReadOnly && [theClient.comparePath length])
			[self.pathMonitor addClientID:theClient.uniqueID forPath:theClient.comparePath];
	}
}

- (void)removeClient:(NTFileSystemEventCenterClient*)theClient;
{
	if (theClient.comparePath)
	{
		NSMutableDictionary *theClients = self.clients;
		if ([theClient includeSubfolders])
			theClients = self.subfolderClients;
		
		NSMutableArray* clientArray = [theClients objectForKey:theClient.comparePath];
		NSUInteger removeIndex = [clientArray indexOfObjectIdenticalTo:theClient];
		
		if (removeIndex != NSNotFound)
		{
			[clientArray removeObjectAtIndex:removeIndex];
			
			// delete array if empty
			if ([clientArray count] == 0)
				[theClients removeObjectForKey:theClient.comparePath];
		}
		else
			NSLog(@"-[%@ %@] failed to find client", NSStringFromClass([self class]), NSStringFromSelector(_cmd));	
		
		[self.clientIDMap removeObjectForKey:theClient.uniqueID];

		// remove monitor
		if (!theClient.isReadOnly && [theClient.comparePath length])
			[self.pathMonitor removeClientID:theClient.uniqueID];
	}
}

- (void)notifyClientsWithEvent:(NTFileSystemEventMessage*)theMessage notifyParent:(BOOL)notifyParent;
{	
	NSString* theRelativePath;
	
	if (theMessage)
	{
		theRelativePath = [theMessage relativePath];
		
		// FSEvents has some case problems
		if (!self.caseSensitive)
			theRelativePath = [theRelativePath lowercaseString];
	}		
	else
		theRelativePath = kNTComputerEventClient;
	
	[self doNotifyClientsWithRelativePath:theRelativePath message:theMessage];
	[self doNotifySubfolderClientsWithRelativePath:theRelativePath message:theMessage];
	
	if (notifyParent)
	{
		NSString* parentPath = [theRelativePath stringByDeletingLastPathComponent];
		if (![parentPath isEqualToString:theRelativePath])
			[self doNotifyClientsWithRelativePath:parentPath message:theMessage];
	}
	
	// did path rename
	if (theMessage)
	{		
		self.cachedMountPoint = [theMessage mountPoint];
		
		if (!self.cachedPaths)
		{
			self.cachedPaths = [NSMutableArray array];
			[self.cachedPaths addObject:theRelativePath];
			
			[self processPathsAfterDelay];
		}
		else if (![self.cachedPaths containsObject:theRelativePath])
			[self.cachedPaths addObject:theRelativePath];
	}
}

@end

@implementation NTFileSystemEventClientMgr(Private) 

- (void)doNotifySubfolderClientsWithRelativePath:(NSString*)theRelativePath message:(NTFileSystemEventMessage*)theMessage;
{
	NSArray *theClients = [self subfolderClientsForRelativePath:theRelativePath];
	
	for (NTFileSystemEventCenterClient *theClient in theClients)
		[theClient notify:theMessage];	
}

- (void)doNotifyClientsWithRelativePath:(NSString*)theRelativePath message:(NTFileSystemEventMessage*)theMessage;
{
	NSArray *theClients = [self clientsForRelativePath:theRelativePath];
	
	for (NTFileSystemEventCenterClient *theClient in theClients)
		[theClient notify:theMessage];
}	

- (NSArray*)subfolderClientsForRelativePath:(NSString*)theRelativePath;
{
	NSArray* result = nil;
	
	NSMutableArray* clientArray = [NSMutableArray array];
	NSArray *theKeys = [self.subfolderClients allKeys];
	
	for (NSString* thePath in theKeys)
	{
		BOOL add = NO;
		
		if ([thePath length] == 0) // root of volume, it listens to all changes
			add = YES;
		else if ([theRelativePath hasPrefix:thePath])
		{
			NSUInteger pathLen = [thePath length];
			if ([theRelativePath length] == pathLen)
				add = YES;
			else if ([theRelativePath length] > pathLen)
			{
				// make sure it's not a case like test/folder, test/folder5/fred
				if ([theRelativePath characterAtIndex:pathLen] == '/')
					add = YES;
			}
		}
		
		if (add)
			[clientArray addObjectsFromArray:[self.subfolderClients objectForKey:thePath]];
	}
	
	if ([clientArray count])
		result = [NSArray arrayWithArray:clientArray];
	
	return result;	
}

- (NSArray*)clientsForRelativePath:(NSString*)theRelativePath;
{
	NSArray* result = nil;
	
	NSMutableArray* clientArray = [self.clients objectForKey:theRelativePath];
	
	if ([clientArray count])
		result = [NSArray arrayWithArray:clientArray];
	
	return result;
}

- (void)processPathsAfterDelay;
{		
	NSTimeInterval after = 2;
	dispatch_time_t theTime = dispatch_time(DISPATCH_TIME_NOW, after * NSEC_PER_SEC);
	
	// must be dispatch_get_current_queue to ensure thread safety 
	dispatch_after(theTime, dispatch_get_current_queue(), ^{
		@try {
			NSArray* clientIDs = [self.pathMonitor processPaths:self.cachedPaths mountPoint:self.cachedMountPoint];
			for (id theClientID in clientIDs)
			{
				NTFileSystemEventCenterClient* theClient = [self.clientIDMap objectForKey:theClientID];
				
				if (theClient)
				{
					// remove, refresh and add back the client to use new path
					[self removeClient:theClient];
					[theClient initializeValues];
					[self addClient:theClient];
				}
				else
					NSLog(@"-[%@ %@] failed to find client", NSStringFromClass([self class]), NSStringFromSelector(_cmd));	
			}
		}
		@catch (NSException * e) {
			NSLog(@"%@ exception (global_queue): %@", NSStringFromSelector(_cmd), e);
		}
		@finally {
			// reset state
			self.cachedMountPoint = nil;
			self.cachedPaths = nil;
		}
	});
}

@end

