//
//  NTIcon.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Wed Aug 14 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTIcon.h"
#import "NSImage-CocoatechFile.h"
#import "NTIconStore.h"
#import "NTIconCompositor.h"

@interface NTIcon ()
@property (nonatomic, assign) IconRef iconRef;
@end

@implementation NTIcon

@synthesize iconRef;

// we are responsible for releasing
+ (id)iconWithRef:(IconRef)ref;
{
    NTIcon* result = [[NTIcon alloc] init];

	if (ref)
    {		
        OSErr err = AcquireIconRef(ref);
		
        if (err == noErr)
            result.iconRef = ref;
    }	
	
    return [result autorelease];
}

- (void)dealloc;
{
    if (self.iconRef)
        ReleaseIconRef(self.iconRef);

    [super dealloc];
}

- (NSImage*)image;
{	
	NSImage* result = [[[NSImage alloc] initWithIconRef:self.iconRef] autorelease];
		
	[result setScalesWhenResized:YES];
	 
	return result;
}

- (NSUInteger)maxSizeAvailable;
{
	NSUInteger result = 512;
	if (!IsDataAvailableInIconRef(kIconServices512PixelDataARGB, [self iconRef]))
	{
		result = 256;
		if (!IsDataAvailableInIconRef(kIconServices256PixelDataARGB, [self iconRef]))
			result = 128;
	}
	
	return result;
}

- (NSImage*)imageForSize:(int)size;
{
	return [self imageForSize:size label:0 select:NO alpha:1.0];
}

- (NSImage*)imageForSize:(int)size label:(int)label select:(BOOL)select;
{
    return [self imageForSize:size label:label select:select alpha:1.0];
}

- (NSImage*)imageForSize:(int)size label:(int)label select:(BOOL)select alpha:(float)alpha;
{
    return [self imageForSize:size label:label select:select alpha:alpha alignment:kAlignAbsoluteCenter];
}

- (NSImage*)imageForSize:(int)size
				   label:(int)label
				  select:(BOOL)select 
				   alpha:(float)alpha 
			   alignment:(int)alignment;
{
	return [NSImage iconRef:self.iconRef toImage:size label:label select:select alpha:alpha alignment:alignment];
}

@end
