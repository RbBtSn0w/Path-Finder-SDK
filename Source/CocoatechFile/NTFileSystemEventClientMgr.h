//
//  NTFileSystemEventClientMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/23/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileSystemEventCenterClient, NTPathMonitor, NTFileSystemEventMessage;

@interface NTFileSystemEventClientMgr : NSObject {
	NSMutableDictionary* clients;
	NSMutableDictionary* clientIDMap;
	NSMutableDictionary* subfolderClients;
	BOOL caseSensitive;
	NTPathMonitor* pathMonitor;
	
	NSMutableArray* cachedPaths;
	NSString* cachedMountPoint;	
}

+ (NTFileSystemEventClientMgr*)clientMgr:(BOOL)caseSensitive;

- (BOOL)isEmpty;

- (void)addClient:(NTFileSystemEventCenterClient*)theClient;
- (void)removeClient:(NTFileSystemEventCenterClient*)theClient;

- (void)notifyClientsWithEvent:(NTFileSystemEventMessage*)theMessage notifyParent:(BOOL)notifyParent;

@end
