//
//  NTPathMonitorDatabase.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 5/6/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTPathMonitorDatabase : NSObject {
	NSMutableDictionary* dictionary;
}

+ (NTPathMonitorDatabase*)database;

- (void)setObject:(id)theObject forKey:(id)theKey1 forKey:(id)theKey2;
- (void)removeObject:(id)theObject forKey:(id)theKey1 forKey:(id)theKey2;  // object must be identical (same pointer) as sent to setObject

- (NSMutableArray*)objectsForKey:(id)theKey1 forKey:(id)theKey2;
- (NSArray*)keysForKey:(id)theKey1;

@end
