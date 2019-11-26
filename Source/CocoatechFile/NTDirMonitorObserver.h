//
//  NTDirMonitorObserver.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFSEventClient, NTDirMonitorItem;

@interface NTDirMonitorObserver : NSObject 
{
	NTMessageProxy* proxy;
	NTFSEventClient *eventClient;
	NSMutableArray* mutableObservers;
	NTDirMonitorItem *item;
}

- (NSArray*)observers;

+ (NTDirMonitorObserver*)observer:(NTDirMonitorItem*)theItem;

- (void)addObserver:(NTMessageProxy*)theObserver;
- (void)removeObserver:(NTMessageProxy*)theObserver;

- (BOOL)empty;
@end
