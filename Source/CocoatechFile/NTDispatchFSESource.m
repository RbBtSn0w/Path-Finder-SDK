//
//  NTDispatchFSESource.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/11/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTDispatchFSESource.h"
#import "NTDirMonitorMgr.h"
#import "NTDirMonitorItem.h"

@interface NTDispatchFSESource ()
@property (nonatomic, retain) NTMessageProxy* delegateProxy;
@property (nonatomic, retain) NTFileDesc *desc;
@property (nonatomic, retain) NTMessageProxy *proxy; 
@property (nonatomic, retain) NTDirMonitorItem *sourceItem; 
@end

@interface NTDispatchFSESource(Private)
@end

@interface NTDispatchFSESource(Protocols) <NTMessageProxyProtocol>
@end

@implementation NTDispatchFSESource

@synthesize delegateProxy;
@synthesize desc, proxy, sourceItem;

+ (NTDispatchFSESource*)source:(NTFileDesc*)desc delegateProxy:(NTMessageProxy*)delegateProxy;
{
	NTDispatchFSESource* result = [[self alloc] init];
		
	result.delegateProxy = delegateProxy;
	[result setDesc:desc];
	
	result.sourceItem = [NTDirMonitorItem item:result.desc];
	result.proxy = [NTMessageProxy proxy:result];

	[[NTDirMonitorMgr sharedInstance] addObserver:result.proxy forItem:result.sourceItem];
	
	return [result autorelease];
}

- (void)dealloc
{	
	[[NTDirMonitorMgr sharedInstance] removeObserver:self.proxy forItem:self.sourceItem];

	[self.proxy invalidate];
	self.proxy = nil;
	
	self.delegateProxy = nil;
	
    [self setDesc:nil];
			
	self.sourceItem = nil;
		
    [super dealloc];
}

@end

@implementation NTDispatchFSESource (Protocols)

// NTMessageProxyProtocol

- (void)messageProxy:(NTMessageProxy*)theProxy message:(id)theMessage;
{	
	// get a fresh one
	self.desc = [self.desc freshDesc];
	
	// tell the delegateProxy
	[self.delegateProxy notify:nil];
}

@end

@implementation NTDispatchFSESource(Private)

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@ : %@", NSStringFromClass([self class]), [[self desc] path]];
}

@end
