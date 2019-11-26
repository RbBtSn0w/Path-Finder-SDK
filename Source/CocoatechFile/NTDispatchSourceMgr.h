//
//  NTDispatchSourceMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTDispatchSourceObserver, NTDispatchSourceItem;

@interface NTDispatchSourceMgr : NTSingletonObject
{
	NSMutableDictionary* sourceObservers;
	dispatch_queue_t dispatchQueue;
}

// returns the identifier, use that to remove
- (void)addObserver:(NTMessageProxy*)theObserver forItem:(NTDispatchSourceItem*)theItem;
- (void)removeObserver:(NTMessageProxy*)theObserver forItem:(NTDispatchSourceItem*)theItem;

@end

// internal access
@interface NTDispatchSourceMgr (NTDispatchSourceObserverAccess)
- (void)sourceObserverWasModified:(NSString*)itemIdentifier;
@end

