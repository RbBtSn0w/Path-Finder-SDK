//
//  NTSVNUIController.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTPathFinderPluginHostProtocol.h"

@class NTSVNToolPathMgr,NTSVNDisplayMgr, NTSVNTextResult, NTSVNStatusResult;

@interface NTSVNUIController : NSObject 
{
	id<NTPathFinderPluginHostProtocol> host;
	WebView* mWebView;
	
	NSRect mDocumentVisibleRect;
	BOOL mRestoreScrollPosition;
	
	id<NTFSItem> mDirectory;
	
	NSMutableSet * mLaunchedTools; // NSNumber: the ID of the plugins launched by us
	NSNumber* mWhichSVNCommand;
	
	NTSVNDisplayMgr* mDisplayMgr;
	NSString* mHTMLHeaderString;  // read from htmlHeader.txt, cached for speed
	
	NTSVNToolPathMgr* toolPathMgr;
}

@property (nonatomic, retain) id<NTPathFinderPluginHostProtocol> host;
@property (readonly, nonatomic, retain) NTSVNToolPathMgr *toolPathMgr;

+ (NTSVNUIController*)controller:(id<NTPathFinderPluginHostProtocol>)theHost 
					 toolPathMgr:(NTSVNToolPathMgr*)toolPathMgr;

- (NSView *)view;
- (void)updateDirectory;

@end
