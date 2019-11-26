//
//  NTSVNToolPathMgr.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 10/16/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTSVNToolPathMgr.h"

@interface NTSVNToolPathMgr ()
@property (nonatomic, retain) NSString *SVNTool;
@property (nonatomic, retain) id<NTPathFinderPluginHostProtocol> host;
@end

@interface NTSVNToolPathMgr (Private)
- (void)initializeSVNPath;
- (void)startPanel:(NSString*)startPath window:(NSWindow*)window;
@end

@implementation NTSVNToolPathMgr

@synthesize SVNTool;
@synthesize host;

+ (NTSVNToolPathMgr*)pathMgr:(id<NTPathFinderPluginHostProtocol>)theHost;
{
	NTSVNToolPathMgr* result = [[NTSVNToolPathMgr alloc] init];
	
	result.host = theHost;
	
	return [result autorelease];
}

- (id)init;
{
	self = [super init];
	
	[self initializeSVNPath];
	
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.SVNTool = nil;
	self.host = nil;
	
    [super dealloc];
}

- (IBAction)selectSVNToolPathAction:(id)sender;
{
	[self startPanel:[self SVNTool] window:[self.host sheetWindow:nil]];
}

@end

@implementation NTSVNToolPathMgr (Private)

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton)
	{
		NSString* thePath = [sheet filename];
		
		if ([[NSFileManager defaultManager] isExecutableFileAtPath:thePath])
		{
			self.SVNTool = thePath;
			
			[[NSUserDefaults standardUserDefaults] setObject:self.SVNTool forKey:@"SVNToolPath"];
		}
		else
			NSBeep();
	}
	
	[sheet orderOut:self];
}

- (void)startPanel:(NSString*)startPath window:(NSWindow*)window;
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseDirectories:NO];
	[op setCanChooseFiles:YES];
	[op setAllowsMultipleSelection:NO];
	[op setShowsHiddenFiles:YES];
	
	[op setPrompt:@"Choose SVN tool"];
		
	if (window)
		[op beginSheetForDirectory:startPath file:nil types:nil modalForWindow:window modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	else
	{
		int result = [op runModalForDirectory:startPath file:nil types:nil];
		if (result == NSOKButton)
		{
			self.SVNTool = [op filename];
			[[NSUserDefaults standardUserDefaults] setObject:self.SVNTool forKey:@"SVNToolPath"];
		}
		
		// must hide the sheet before we send out the action, otherwise our window wont get the action
		[op orderOut:nil];
	}
}

- (void)initializeSVNPath;
{
	NSArray* paths = [NSArray arrayWithObjects:
					  @"/usr/local/bin/svn",
					  @"/opt/local/bin/svn",
					  @"/sw/bin/svn",
					  @"/usr/bin/svn",  // search last so any user installed versions get found first
					  nil];
	
	NSString* prefsPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"SVNToolPath"];
	if ([prefsPath length])
		paths = [[NSArray arrayWithObject:prefsPath] arrayByAddingObjectsFromArray:paths];
	
	for (NSString* path in paths)
	{
		if ([[NSFileManager defaultManager] isExecutableFileAtPath:path])
		{
			self.SVNTool = path;
			break;
		}
	}
}	

@end

