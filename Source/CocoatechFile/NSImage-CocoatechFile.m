//
//  NSImage-Extensions.m
//  CocoatechFile
//
//  Created by sgehrman on Fri Oct 12 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NSImage-CocoatechFile.h"
#import "NTIconCompositor.h"
#import "NTFileTypeIdentifier.h"
#import "NTResourceMgr.h"
#import "NTQuickLookThumbnail.h"
#import "NTImageStore.h"

@implementation NSImage (CocoatechFile)

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size
{
    return [NSImage iconRef:iconRef toImage:size select:NO];
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size select:(BOOL)select;
{
    return [NSImage iconRef:iconRef toImage:size label:0 select:select];
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label select:(BOOL)select;
{
    return [NSImage iconRef:iconRef toImage:size label:label select:select alpha:1.0];
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label select:(BOOL)select alpha:(float)alpha;
{
	return [NSImage iconRef:iconRef toImage:size label:label select:select alpha:1.0 alignment:kAlignAbsoluteCenter];
}

+ (NSImage*)iconRef:(IconRef)iconRef
			toImage:(int)size 
			  label:(int)label 
			 select:(BOOL)select
			  alpha:(float)alpha
		  alignment:(int)alignment;
{
	NTImageMaker* maker = [NTImageMaker maker:NSMakeSize(size,size)];

    [maker lockFocus];
    [NTIconCompositor drawIconForRef:iconRef inRect:NSMakeRect(0,0,size,size) label:label selected:select flip:NO alpha:alpha alignment:alignment];
	return [maker unlockFocus];
}

+ (NSImage*)iconRef:(IconRef)iconRef toImage:(int)size label:(int)label highlight:(BOOL)highlight; // used when clicking on an image button
{
    NSImage* original = [self iconRef:iconRef toImage:size label:label select:NO];
	
	if (highlight)
	{
		NTImageMaker* maker = [NTImageMaker maker:NSMakeSize(size,size)];
		
		[maker lockFocus];
		
		[original compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
		
		[[[NSColor blackColor] colorWithAlphaComponent:.5] set];
		NSRectFillUsingOperation(NSMakeRect(0,0,size,size) ,NSCompositeSourceAtop);
		
		return [maker unlockFocus];    
	}
	
	return original;
}

// add a badge to an image, badge added to all imageReps
- (NSImage*)imageWithBadge:(NSImage*)badgeImage;
{
    NSImage* result = [[[NSImage alloc] initWithSize:[self size]] autorelease];
    NSArray* reps = [self representations];

    for (NSImageRep *rep in reps)
    {
        NSRect imageRect = NSMakeRect(0,0,[rep size].width, [rep size].height);
               
		NTImageMaker* imageMaker = [NTImageMaker maker:[rep size]];
        
        [imageMaker lockFocus];
        [self drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [badgeImage drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [imageMaker unlockFocus];
        
        [result addRepresentation:[imageMaker imageRep]];
    }
    
    return result;
}

- (void)drawIconInRect:(NSRect)theRect aliasBadge:(BOOL)aliasBadge;
{
	[self drawInRect:theRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
	
	if (aliasBadge)
	{
		static NSImage* shared = nil;
		
		if (!shared)
			shared = [[NTMS aliasBadge] retain];
		
		[shared drawInRect:theRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
	}
}

// call from thread, could be slow
+ (NSImage*)quickLookPreviewImageOrIcon:(NTFileDesc*)desc 
								 ofSize:(NSSize)ofSize 
								 asIcon:(BOOL)asIcon;
{
	NSImage* image = nil;
	
	// too slow over a network
	if (![desc isNetwork])
	{
		image = [self quickLookPreviewImage:desc 
									 ofSize:ofSize
									 asIcon:asIcon];
	}
	
	if (!image)
	{
		int theSize = MIN(ofSize.width, ofSize.height);
		
		theSize = MIN(512, theSize);
		
		image = [[desc iconImage] imageWithSetSize:theSize];
	}
	
	return image;	
}

// called from thread
+ (NSImage *)quickLookPreviewImage:(NTFileDesc*)desc
							ofSize:(NSSize)size
							asIcon:(BOOL)icon;
{
	return [NTQuickLookThumbnail previewImage:[desc URL]
											   ofSize:size
											   asIcon:icon];
}

@end
