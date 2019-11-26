//
//  NTSVNModulePlugin.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 5/6/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNModulePlugin.h"
#import "NTSVNUIController.h"
#import "NTSVNToolPathMgr.h"

@interface NTSVNModulePlugin ()
@property (nonatomic, retain) NTSVNToolPathMgr *toolPathMgr;
@end

@interface NTSVNModulePlugin (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTSVNModulePlugin (Protocols) <NTModulePluginProtocol>
@end

@implementation NTSVNModulePlugin

@synthesize UIController, toolPathMgr;

- (void)dealloc;
{
	[self setView:nil];
    [self setUIController:nil];
	self.toolPathMgr = nil;
	
    [super dealloc];
}

@end

@implementation NTSVNModulePlugin (Protocols)

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)theHost;
{
    NTSVNModulePlugin* result = [[self alloc] init];
	
	result.toolPathMgr = [NTSVNToolPathMgr pathMgr:theHost];
	[result setUIController:[NTSVNUIController controller:theHost toolPathMgr:result.toolPathMgr]];

    return [result autorelease];
}

	// return an NSMenuItem to be used in the plugins menu.  You can add a submenu to this item if you need more menu choices
	// be sure to implement - (BOOL)validateMenuItem:(NSMenuItem*)menuItem; in your menuItems target to enable/disable the menuItem
- (NSView*)view;
{
	if (!mView)
		[self setView:[[self UIController] view]];
	
	return mView;
}

- (void)setView:(NSView *)theView
{
    if (mView != theView)
    {
        [mView release];
        mView = [theView retain];
    }
}

- (NSMenu*)menu;
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSMenuItem* menuItem;
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"SVN=\"%@\"...", self.toolPathMgr.SVNTool] action:@selector(selectSVNToolPathAction:) keyEquivalent:@""] autorelease];
	[menuItem setTarget:self.toolPathMgr];
	[menu addItem:menuItem];
	
	return menu;
}

- (void)browserEvent:(NTBrowserEventType)event browserID:(NSString*)theBrowserID;
{
	NSString* syncToBrowserID = [[self.UIController host] syncToBrowserID];
	if (syncToBrowserID && theBrowserID)
	{
		if (![syncToBrowserID isEqualToString:theBrowserID])
			return;  // if we are watching a certain browserID, and this one doesn't match, bail
	}
	
	if ((event & kSelectionUpdated_browserEvent) == kSelectionUpdated_browserEvent)
	{
	}
	if ((event & kContainingDirectoryUpdated_browserEvent) == kContainingDirectoryUpdated_browserEvent)
	{
		[[self UIController] updateDirectory];
	}
	if ((event & kModuleWasHidden_browserEvent) == kModuleWasHidden_browserEvent)
	{
	}
}

@end

