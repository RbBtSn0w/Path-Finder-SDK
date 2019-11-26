//
//  NTFSWatcherItem.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFSWatcherItem.h"
#import "NTFileDesc.h"
#import "NTVolume.h"
#import "NTFSEventClient.h"
#import "NTDefaultDirectory.h"
#import "NTDispatchSourceMgr.h"
#import "NTDispatchSourceItem.h"

@interface NTFSWatcherItem ()
@property (nonatomic, retain) NTFileDesc *desc;
@property (nonatomic, retain) NTDispatchSourceItem *sourceItem;
@property (nonatomic, retain) NTMessageProxy* proxy;
@property (nonatomic, retain) NTFSEventClient *eventClient;
@property (nonatomic, retain) NTMessageProxy *delegateProxy;
@end

@interface NTFSWatcherItem (Protocols) <NTMessageProxyProtocol>
@end

@implementation NTFSWatcherItem

@synthesize desc;
@synthesize eventClient;
@synthesize sourceItem, proxy;
@synthesize delegateProxy;

- (void)dealloc
{
	[self.proxy invalidate];
	self.proxy = nil;

    [self setDesc:nil];
	self.delegateProxy = nil;

	if (self.sourceItem)
	{
		[[NTDispatchSourceMgr sharedInstance] removeObserver:self.proxy forItem:self.sourceItem];
		
		self.sourceItem = nil;
	}
	
	self.eventClient = nil;
	
    [super dealloc];
}

+ (NTFSWatcherItem*)itemWithDesc:(NTFileDesc*)desc delegateProxy:(NTMessageProxy*)delegateProxy;
{
	NTFSWatcherItem* result = nil;
	
	if ([desc isValid])
	{
		result = [[NTFSWatcherItem alloc] init];

		result.delegateProxy = delegateProxy;
		 
		[result setDesc:desc];
		result.proxy = [NTMessageProxy proxy:result];
		
		if ([desc isComputer])
			result.eventClient = [NTFSEventClient client:result.proxy folder:[[NTDefaultDirectory sharedInstance] computer]];
		else
		{
			result.sourceItem = [NTDispatchSourceItem item:desc];
			
			[[NTDispatchSourceMgr sharedInstance] addObserver:result.proxy forItem:result.sourceItem];
		}
	}
	
	return [result autorelease];
}	

- (void)refreshDesc;
{
	[self setDesc:[[self desc] freshDesc]];
}

@end

@implementation NTFSWatcherItem (Protocols)

// NTMessageProxyProtocol
- (void)messageProxy:(NTMessageProxy*)theProxy message:(id)inMessage;
{
	[self.delegateProxy notify:self.desc];
}

@end


