//
//  NTPathMonitor.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 5/6/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTPathMonitorDatabase;

@interface NTPathMonitor : NSObject 
{
	NTPathMonitorDatabase* database;
	NSMutableDictionary* clientKeyMap;
}

+ (NTPathMonitor*)pathMonitor;

- (void)addClientID:(id)theClientID forPath:(NSString*)thePath;
- (void)removeClientID:(id)theClientID;

// returns client ids that have changed
- (NSArray*)processPaths:(NSArray*)thePaths mountPoint:(NSString*)theMountPoint;

@end
