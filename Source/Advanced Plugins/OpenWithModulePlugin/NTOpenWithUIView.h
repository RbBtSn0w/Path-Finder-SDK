//
//  NTOpenWithUIView.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTOpenWithUIView : NSView
{
	BOOL drawsBackground;
}

@property (nonatomic, assign) BOOL drawsBackground;

@end
