//
//  NTThumbnail.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/15/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTThumbnail.h"
#import "NTFileTypeIdentifier.h"
#import "NTQuickLookThumbnail.h"
#import "NSImage-CocoatechFile.h"

@interface NTThumbnail ()
@property (retain) NSImage* image;
@property (retain) NSImage* selectedImage;
@property (assign) BOOL isValid;
@property (assign) BOOL drawFrame;
@property (assign) NSSize maxSize;
@end

@implementation NTThumbnail

@synthesize isValid;
@synthesize image, selectedImage;
@synthesize drawFrame, maxSize;

+ (NTThumbnail*)thumbnailWithDesc:(NTFileDesc*)desc
						   asIcon:(BOOL)asIcon
						  maxSize:(NSSize)maxSize;
{
	NTThumbnail *result = [[NTThumbnail alloc] init];
	result.maxSize = maxSize;
	
	result.image = [NSImage quickLookPreviewImage:desc ofSize:maxSize asIcon:asIcon];
	if (result.image)			
	{			
		// set frame for pdfs
		if (!asIcon && [[desc typeIdentifier] isPDF])
			result.drawFrame = YES;
		
		if (!NSEqualSizes(NSZeroSize, result.image.size))
			[result setIsValid:YES];
	}
	
	return [result autorelease];	
}

+ (NTThumbnail*)thumbnailWithImage:(NSImage*)image;
{
	NTThumbnail *result = [[NTThumbnail alloc] init];
	
	if (image)			
	{		
		if (!NSEqualSizes(NSZeroSize, [image size]))
		{			
			result.maxSize = [image size];

			[result setImage:image];
			
			[result setIsValid:YES];
		}
	}
		
	return [result autorelease];	
}

- (void)dealloc
{
    self.image = nil;
    self.selectedImage = nil;
    [super dealloc];
}

- (NSRect)imageRectForRect:(NSRect)rect;
{
	NSRect containerRect = NSZeroRect;
	containerRect.size = rect.size;
	
	// the max container rect, don't want to go bigger than the source image
	containerRect = [NTGeometry rect:containerRect centeredIn:rect scaleToFitContainer:YES];
	
	NSRect drawRect = NSZeroRect;
	drawRect.size = [self.image size];
	
	// image will get distorted if not the right rect, adjust and center rect before calling
	drawRect = [NTGeometry rect:drawRect centeredIn:containerRect scaleToFitContainer:YES canScaleLarger:YES]; // canScaleLarger YES added to 5.1.4
	
	// avoid the fuzzies
	drawRect.origin.x = (int)drawRect.origin.x;
	drawRect.origin.y = (int)drawRect.origin.y;	
	
	return drawRect;
}

- (void)drawInRect:(NSRect)rect
		   flipped:(BOOL)flipped
		  selected:(BOOL)selected;
{
	if (![self isValid])
		return;
	
	NSRect drawRect = [self imageRectForRect:rect];
	if (selected)
	{
		if (!self.selectedImage)
			self.selectedImage = [self.image selectedImage:drawRect.size];
		
		[self.selectedImage drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:flipped hints:nil];
	}
	else
		[[self image] drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:flipped hints:nil];
	
	if (self.drawFrame)
	{
		[[NSColor blackColor] set];
		NSFrameRectWithWidth(drawRect, .5);
	}	
}

@end
