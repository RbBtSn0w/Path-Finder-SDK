//
//  NTFSWatcher.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFSWatcher.h"
#import "NTFSWatcherItem.h"
#import "NTFileEnvironment.h"

@interface NTFSWatcher ()
@property (nonatomic, assign) id<NTFSWatcherDelegateProtocol> delegate;  // not retained
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSMutableDictionary *descsToNotify;
@property (nonatomic, assign) BOOL sendingDelayedNotification;
@property (nonatomic, retain) NTMessageProxy* proxy;
@end

@interface NTFSWatcher (Private)
- (void)removeAll;
@end

@interface NTFSWatcher (Protocols) <NTMessageProxyProtocol>
@end

@implementation NTFSWatcher

@synthesize delegate;
@synthesize items;
@synthesize descsToNotify;
@synthesize sendingDelayedNotification;
@synthesize proxy;

- (void)dealloc
{
	[self.proxy invalidate];
	self.proxy = nil;
	
	if ([self delegate])
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];
		
    self.items = nil;
    self.descsToNotify = nil;
	
    [super dealloc];
}

+ (NTFSWatcher*)watcher:(id<NTFSWatcherDelegateProtocol>)delegate;
{
	NTFSWatcher* result = [[NTFSWatcher alloc] init];
	
	result.proxy = [NTMessageProxy proxy:result];

	[result setDescsToNotify:[NSMutableDictionary dictionary]];
	[result setItems:[NSMutableArray array]];
	[result setDelegate:delegate];
	
	return [result autorelease];
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
}

- (void)refreshDescs;  // update the descs so we can check for hasBeenModified etc
{
	for (NTFSWatcherItem* item in [self items])
		[item refreshDesc];
}

// files/directories I'm watching
- (NSArray*)watchedDescs;
{
	NSMutableArray* result = [NSMutableArray array];
	
	for (NTFSWatcherItem* item in [self items])
		[result addObject:[item desc]];
	
	return result;
}

// replaces (removeAll, add)
- (void)watchItems:(NSArray*)theDescs;
{
    [self removeAll];

	// cache for speed
	NSMutableArray* theItems = [self items];
	
	for (NTFileDesc* theDesc in theDescs)
	{		
		// 500 limit. If the user selects a huge folder I don't want my selection monitoring code to bog down the system
		if ([theItems count] > 500)
			break;
		
		NTFSWatcherItem* item = [NTFSWatcherItem itemWithDesc:theDesc delegateProxy:self.proxy];
		if (item)
			[theItems addObject:item];
	}		
}

- (void)watchItem:(NTFileDesc*)theDesc;
{	
	if (theDesc)
		[self watchItems:[NSArray arrayWithObject:theDesc]];
}

@end

@implementation NTFSWatcher (Private)

- (void)removeAll;
{	
	[[self items] removeAllObjects];
	
	[[self descsToNotify] removeAllObjects];
}

- (void)delayedNotification;
{	
	NSArray *tmp = [[self descsToNotify] allValues];
	[[self descsToNotify] removeAllObjects];
	
	[[self delegate] watcher:self itemsChanged:tmp];
	
	[self setSendingDelayedNotification:NO];
}

@end

@implementation NTFSWatcher (Protocols)

// NTMessageProxyProtocol
- (void)messageProxy:(NTMessageProxy*)theProxy message:(id)theMessage;
{
	NTFileDesc* desc = (NTFileDesc*)theMessage;
	NSString* key = [desc dictionaryKey];
	
	if (![[self descsToNotify] objectForKey:key])
	{
		[[self descsToNotify] setObject:desc forKey:key];	
		
		if (![self sendingDelayedNotification])
		{
			[self setSendingDelayedNotification:YES];
			[self performSelector:@selector(delayedNotification) withObject:nil afterDelay:.2];
		}
	}
}

@end

