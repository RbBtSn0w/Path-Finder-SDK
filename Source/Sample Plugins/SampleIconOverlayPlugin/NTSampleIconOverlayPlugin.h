//
//  NTSampleIconOverlayPlugin.h
//  IconOverlay
//
//  Created by Steve Gehrman on Wed Mar 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTIconOverlayPluginProtocol.h"

@interface NTSampleIconOverlayPlugin : NSObject <NTIconOverlayPluginProtocol>
{
    id<NTPathFinderPluginHostProtocol> host;
	NSImage* privateBadge;
	NSImage* dropFolderBadge;
	NSUInteger count;
	NSMutableSet* xyzFiles;
	BOOL sentDelayedRefreshOverlays;
}

@end
