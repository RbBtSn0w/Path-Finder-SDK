//
//  NTFileSystemEventCenter.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/23/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileSystemEventListener, NTFileSystemEventCenterClient;

@interface NTFileSystemEventCenter : NTSingletonObject {
	NSMutableDictionary *clientMgrs; // key = mountPath, object = NTFileSystemEventClientMgr
	NSMutableDictionary *volumeIDMap;
	
	NTMessageProxy* messageProxy;
	NTFileSystemEventListener *eventListener;
	dispatch_queue_t dispatchQueue;
}

- (void)addEventClient:(NTFileSystemEventCenterClient*)theClient;
- (void)removeEventClient:(NTFileSystemEventCenterClient*)theClient;

- (void)manuallyNotifyClientsForPath:(NSString*)thePath;

@end

@interface NTFileSystemEventCenter(PathUtilities)
+ (NSString*)volumeIDForPath:(NSString*)thePath;
+ (NSString*)volumeIDForMountPoint:(NSString*)mountPoint;
@end


