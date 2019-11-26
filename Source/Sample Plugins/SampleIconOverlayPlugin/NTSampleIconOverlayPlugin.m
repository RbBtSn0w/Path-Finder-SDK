//
//  NTSampleIconOverlayPlugin.m
//  IconOverlay
//
//  Created by Steve Gehrman on Wed Mar 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTSampleIconOverlayPlugin.h"

@interface NTSampleIconOverlayPlugin ()
@property (nonatomic, retain) id<NTPathFinderPluginHostProtocol> host;
@property (nonatomic, retain) NSImage *privateBadge;

@property (nonatomic, retain) NSImage *dropFolderBadge;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, retain) NSMutableSet *xyzFiles;
@property (nonatomic, assign) BOOL sentDelayedRefreshOverlays;
@end

@interface NTSampleIconOverlayPlugin (Private)
- (void)refreshOverlayWithURL:(NSURL*)theURL;
- (void)refreshAllOverlays;
- (void)refreshOverlays;
@end

@implementation NTSampleIconOverlayPlugin

@synthesize host, privateBadge;
@synthesize dropFolderBadge;
@synthesize count;
@synthesize xyzFiles, sentDelayedRefreshOverlays;

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;
{
    NTSampleIconOverlayPlugin* result = [[self alloc] init];
	NSURL* theURL;
	NSBundle* theBundle = [NSBundle bundleWithPath:@"/System/Library/CoreServices/CoreTypes.bundle"];

	result.host = host;
	result.xyzFiles = [NSMutableSet setWithCapacity:12];
	
	theURL = [theBundle URLForImageResource:@"PrivateFolderBadgeIcon"];
	if (theURL)
		result.privateBadge = [[[NSImage alloc] initWithContentsOfURL:theURL] autorelease];
	
	theURL = [theBundle URLForImageResource:@"DropFolderBadgeIcon"];
	if (theURL)
		result.dropFolderBadge = [[[NSImage alloc] initWithContentsOfURL:theURL] autorelease];
	
    return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.host = nil;
	self.privateBadge = nil;
	self.dropFolderBadge = nil;
    self.xyzFiles = nil;

    [super dealloc];
}

- (NSImage*)overlayForURL:(NSURL*)theURL;
{
	if ([[[theURL pathExtension] lowercaseString] isEqualToString:@"xyz"])
	{		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self refreshOverlays];
		});
		
		@synchronized(self.xyzFiles) {
			[self.xyzFiles addObject:theURL];
		}
		
		if ((self.count % 2) == 0)
			return self.privateBadge;
		else
			return self.dropFolderBadge;
	}
	
	return nil;
}

@end

@implementation NTSampleIconOverlayPlugin (Private)

- (void)refreshOverlayWithURL:(NSURL*)theURL;
{
	NSArray* theURLs = [NSArray arrayWithObject:theURL];;
	[self.host refreshOverlaysWithURLs:theURLs];
}

- (void)refreshAllOverlays;
{
	[self.host refreshAllOverlays];
}

- (void)refreshOverlays;
{
	if (!self.sentDelayedRefreshOverlays)
	{
		self.sentDelayedRefreshOverlays = YES;
		
		[self performSelector:@selector(sentDelayedRefreshOverlaysAfterDelay) withObject:nil afterDelay:5];
	}
}

- (void)sentDelayedRefreshOverlaysAfterDelay;
{
	self.sentDelayedRefreshOverlays = NO;
	self.count += 1;
	
	@synchronized(self.xyzFiles) {
		// set to 0, 1, 2 to test the different ways of refreshing
		int threeWays = 2;
		switch (threeWays) 
		{
			case 0:
				[self refreshAllOverlays];
				break;
			case 1:
				for (NSURL* theURL in self.xyzFiles)
					[self refreshOverlayWithURL:theURL];
				break;
			case 2:
				[self.host refreshOverlaysWithURLs:[self.xyzFiles allObjects]];
				break;
			default:
				break;
		}
	}
}

@end
