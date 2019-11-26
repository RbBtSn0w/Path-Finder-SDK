//
//  NTRenameWatcher.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/27/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTRenameWatcher.h"
#import "NTFSWatcher.h"

@interface NTRenameWatcher ()
@property (nonatomic, assign) id<NTRenameWatcherDelegateProtocol> delegate;  // not retained
@property (nonatomic, retain) NTFileDesc* desc;
@property (nonatomic, retain) NTFSWatcher* fsWatcher;
@property (nonatomic, assign) BOOL sendingDelayedNotification;
@end

@interface NTRenameWatcher (Protocols) <NTFSWatcherDelegateProtocol>
@end

@implementation NTRenameWatcher

@synthesize delegate;
@synthesize desc, fsWatcher;
@synthesize sendingDelayedNotification;

+ (NTRenameWatcher*)watcher:(id<NTRenameWatcherDelegateProtocol>)delegate 
					   desc:(NTFileDesc*)theDesc;
{
	NTFileDesc* parentDesc = [theDesc parentDesc];
	NTRenameWatcher* result=nil;
	
	// if no parent, then watch computer level
	if (!parentDesc)
		parentDesc = [NTFileDesc descNoResolve:@""];
	
	if (parentDesc)
	{
		result = [[NTRenameWatcher alloc] init];
		
		[result setDesc:theDesc];
		[result setDelegate:delegate];
		
		result.fsWatcher = [NTFSWatcher watcher:result];
		[result.fsWatcher watchItem:parentDesc];
	}
	
	return [result autorelease];
}

- (void)dealloc
{	
	if ([self delegate])
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];
	
    self.desc = nil;
	
	[self.fsWatcher clearDelegate];
	self.fsWatcher = nil;
	
    [super dealloc];
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
}

@end

@implementation NTRenameWatcher (Private)

- (void)delayedNotification;
{			
	[[self delegate] renameWatcher:self renamed:self.desc];
	
	[self setSendingDelayedNotification:NO];
}

@end

@implementation NTRenameWatcher (Protocols)

// NTFSWatcherDelegateProtocol

- (void)watcher:(NTFSWatcher*)watcher itemsChanged:(NSArray*)descs;
{	
	if ([self.desc hasBeenRenamed])
	{
		if (![self sendingDelayedNotification])
		{
			[self setSendingDelayedNotification:YES];
			[self performSelector:@selector(delayedNotification) withObject:nil afterDelay:.2];
		}
	}
}

@end

