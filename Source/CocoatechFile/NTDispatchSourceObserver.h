//
//  NTDispatchSourceObserver.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTDispatchSource, NTDispatchFSESource, NTDispatchSourceItem;

@interface NTDispatchSourceObserver : NSObject 
{
	NTDispatchSourceItem* item;
	
	NTDispatchSource* source;
	NTDispatchFSESource *fseSource;
	NTMessageProxy *messageProxy;
	
	NSMutableArray* mutableObservers;
}

- (NSArray*)observers;

+ (NTDispatchSourceObserver*)observer:(NTDispatchSourceItem*)theItem;

- (void)addObserver:(NTMessageProxy*)theObserver;
- (void)removeObserver:(NTMessageProxy*)theObserver;

- (BOOL)empty;
@end
