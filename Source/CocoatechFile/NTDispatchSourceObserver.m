//
//  NTDispatchSourceObserver.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/10/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTDispatchSourceObserver.h"
#import "NTDispatchSource.h"
#import "NTDispatchSourceMgr.h"
#import "NTDispatchFSESource.h"
#import "NTDispatchSourceItem.h"

@interface NTDispatchSourceObserver ()
@property (nonatomic, retain) NSMutableArray *mutableObservers;
@property (nonatomic, retain) NTDispatchSource *source;
@property (nonatomic, retain) NTDispatchFSESource *fseSource;
@property (nonatomic, retain) NTMessageProxy *messageProxy;
@property (nonatomic, retain) NTDispatchSourceItem *item;
@end

@interface NTDispatchSourceObserver (Protocols) <NTMessageProxyProtocol>
@end

@implementation NTDispatchSourceObserver

@synthesize mutableObservers;
@synthesize source, fseSource, messageProxy;
@synthesize item;

+ (NTDispatchSourceObserver*)observer:(NTDispatchSourceItem*)theItem;
{
	NTDispatchSourceObserver* result = [[self alloc] init];
	
	result.item = theItem;
	result.mutableObservers = [NSMutableArray array];
	result.messageProxy = [NTMessageProxy proxy:result];
	
	if (theItem.monitorWithFSEvents)
		result.fseSource = [NTDispatchFSESource source:theItem.desc delegateProxy:result.messageProxy];
	else
		result.source = [NTDispatchSource source:theItem.desc delegateProxy:result.messageProxy];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[self.messageProxy invalidate];
	self.messageProxy = nil;
	
	self.source = nil;
	self.fseSource = nil;

    self.mutableObservers = nil;
    self.item = nil;

    [super dealloc];
}

- (void)addObserver:(NTMessageProxy*)theObserver;
{
	[self.mutableObservers addObject:theObserver];
}

- (void)removeObserver:(NTMessageProxy*)theObserver;
{
	[self.mutableObservers removeObjectIdenticalTo:theObserver];
}

- (BOOL)empty;
{
	return ([self.mutableObservers count] == 0);
}

- (NSArray*)observers;
{
	return [NSArray arrayWithArray:self.mutableObservers];
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@ : %@ / %@", NSStringFromClass([self class]), self.source, self.fseSource];
}

@end

@implementation NTDispatchSourceObserver (Protocols)

// <NTMessageProxyProtocol>
- (void)messageProxy:(NTMessageProxy*)theProxy message:(id)theMessage;
{
	[[NTDispatchSourceMgr sharedInstance] sourceObserverWasModified:[self.item identifier]];
}

@end
