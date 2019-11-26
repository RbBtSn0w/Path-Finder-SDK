//
//  NTDirMonitorMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/11/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTDirMonitorObserver, NTDirMonitorItem;

@interface NTDirMonitorMgr : NTSingletonObject
{
	NSMutableDictionary* sourceObservers;
	dispatch_queue_t dispatchQueue;
}

// returns the identifier, use that to remove
- (void)addObserver:(NTMessageProxy*)theObserver forItem:(NTDirMonitorItem*)theItem;
- (void)removeObserver:(NTMessageProxy*)theObserver forItem:(NTDirMonitorItem*)theItem;

@end

// internal access
@interface NTDirMonitorMgr (NTDirMonitorObserverAccess)
- (void)dirMonitorObserverWasModified:(NSString*)itemIdentifer;
@end

