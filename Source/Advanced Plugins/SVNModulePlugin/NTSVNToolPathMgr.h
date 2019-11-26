//
//  NTSVNToolPathMgr.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 10/16/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@interface NTSVNToolPathMgr : NSObject {
	NSString* SVNTool;
	id<NTPathFinderPluginHostProtocol> host;
}

@property (readonly, nonatomic, retain) NSString *SVNTool;

+ (NTSVNToolPathMgr*)pathMgr:(id<NTPathFinderPluginHostProtocol>)theHost;

- (IBAction)selectSVNToolPathAction:(id)sender;
@end
