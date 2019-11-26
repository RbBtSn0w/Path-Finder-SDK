//
//  NTQuickLookThumbnail.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 12/4/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTQuickLookThumbnail.h"
#import "NSImage-CocoatechFile.h"
#import <QuickLook/QuickLook.h>

@interface NTQuickLookThumbnail (Private)
+ (CGImageRef)newPreviewImageRef:(NSURL*)url
					   ofSize:(NSSize)size
					   asIcon:(BOOL)icon;
@end

static NSDictionary* sharedIconOptions = nil;

@implementation NTQuickLookThumbnail

+ (void)initialize;
{
	NTINITIALIZE;
	
	@synchronized(self) {
		if (!sharedIconOptions)
			sharedIconOptions = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kQLThumbnailOptionIconModeKey] retain];
	}
}

// called from thread
+ (NSImage *)previewImage:(NSURL*)url
				   ofSize:(NSSize)size
				   asIcon:(BOOL)icon;
{
	NSImage *result=nil;
	
    CGImageRef ref = [self newPreviewImageRef:url ofSize:size asIcon:icon];
    if (ref) 
	{
        result = [NSImage imageFromCGImageRef:ref];
				
        CFRelease(ref);
    }
	
    return result;
}

@end

@implementation NTQuickLookThumbnail (Private)

// called from thread
+ (CGImageRef)newPreviewImageRef:(NSURL*)url
					   ofSize:(NSSize)size
					   asIcon:(BOOL)icon;
{
	// not sure why, but it fails for less than 24, images seem to work for any size
	// movies seemed to work for 18, PDFS needed 24
	static const int minDimension = 24;

	CGSize cgSize;
	cgSize.width = MAX(minDimension, size.width);
	cgSize.height = MAX(minDimension, size.height);
	
	CGImageRef result=nil;
	@try {
		result = QLThumbnailImageCreate(kCFAllocatorDefault, 
										(CFURLRef)url, 
										cgSize,
										(CFDictionaryRef) ((icon) ? sharedIconOptions : nil));
	}
	@catch (NSException * e) {
		NSLog(@"QLThumbnailImageCreate exception: %@", [e description]);
	}
	@finally {
	}
		
    return result;
}

@end
