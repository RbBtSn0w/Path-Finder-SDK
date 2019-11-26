//
//  NTIconOverlayPluginProtocol.h
//

#import <Cocoa/Cocoa.h>
#import "NTPathFinderPluginHostProtocol.h"

// ==============================================================================================
// required protocol, you must implement this protocol in your principle class

@protocol NTIconOverlayPluginProtocol <NSObject>

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;

- (NSImage*)overlayForURL:(NSURL*)theURL;

@end
