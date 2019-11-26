//
//  NTMetadata.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTMetadata.h"

@interface NTMetadata (Private)
- (NSString *)path;
- (void)setPath:(NSString *)thePath;

- (void)buildAttributesArrays;
- (void)setValueStrings:(NSArray *)theValueStrings;
- (void)setAttributeNames:(NSArray *)theAttributeNames;
@end

@interface NTMetadata (hidden)
- (void)setMdItemRef:(MDItemRef)theMdItemRef;
@end

@implementation NTMetadata

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{	
    [self setMdItemRef:nil];
	[self setPath:nil];
    [self setAttributeNames:nil];
    [self setValueStrings:nil];
	
    [super dealloc];
}

+ (NTMetadata*)metadata:(NSString*)path;
{
	NTMetadata *result = [[NTMetadata alloc] init];
	
	[result setPath:path];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
//  attributeNames 
//---------------------------------------------------------- 
- (NSArray *)attributeNames
{
	[self buildAttributesArrays];
	
    return mv_attributeNames; 
}

//---------------------------------------------------------- 
//  valueStrings 
//---------------------------------------------------------- 
- (NSArray *)valueStrings
{
	[self buildAttributesArrays];
	
    return mv_valueStrings; 
}

//---------------------------------------------------------- 
//  mdItemRef 
//---------------------------------------------------------- 
- (MDItemRef)mdItemRef
{
	if (!mMdItemRef)
	{
		NSString* path = [self path];
		
		if ([path length])
			[self setMdItemRef:MDItemCreate(nil, (CFStringRef)path)];	
	}
	
    return mMdItemRef; 
}

- (void)setMdItemRef:(MDItemRef)theMdItemRef
{
    if (mMdItemRef != theMdItemRef)
    {
		if (mMdItemRef)
			CFRelease(mMdItemRef);
		
        mMdItemRef = theMdItemRef;
    }
}

- (id)valueForAttribute:(NSString*)attribute;
{
	id value=nil;
	
	// this shit crashes if called from multiple threads!  (have more than one info view showing metadata and it crashes without this)
	@synchronized(self) {
		if ([self mdItemRef])
		{
			CFTypeRef theRef = MDItemCopyAttribute([self mdItemRef], (CFStringRef)attribute); 
			
			if (theRef)
			{
				value = (id)theRef;
				value = [[value retain] autorelease];
				
				CFRelease(theRef);
			}
		}
	}
	
	return value;
}

- (NSString*)displayValueForAttribute:(NSString*)attributeName;
{
	id value = [self valueForAttribute:attributeName];
	
	if (value)
		return [self displayValue:value forAttribute:attributeName];
	
	return nil;
}

- (NSString*)displayValue:(id)value forAttribute:(NSString*)attributeName;
{
	NSMutableString* formattedValue;
	
	if ([value respondsToSelector: @selector(descriptionInStringsFileFormat)])
		formattedValue = [[[value descriptionInStringsFileFormat] mutableCopy] autorelease];
	else
	{
		// special cases:
		if ([(NSString*)attributeName isEqualToString:(NSString*)kMDItemDurationSeconds])
		{
			CGFloat secs = [(NSNumber*)value floatValue];
			
			int minutes = secs / 60.0;
			int seconds = (int)secs % 60;
			
			formattedValue = [NSMutableString stringWithFormat:@"%02d'%d%d", minutes, seconds/10, seconds%10];
		}
		else if ([(NSString*)attributeName isEqualToString:(NSString*)kMDItemAudioSampleRate])
		{
			NSUInteger sampleRate = [(NSNumber*)value integerValue];

			formattedValue = [NSMutableString stringWithFormat:@"%d.%03d kHz", sampleRate/1000, sampleRate%1000];
		}
		else if ([(NSString*)attributeName isEqualToString:(NSString*)kMDItemAudioBitRate] || [(NSString*)attributeName isEqualToString:(NSString*)kMDItemTotalBitRate])
		{
			NSUInteger bitRate = [(NSNumber*)value integerValue];
			
			formattedValue = [NSMutableString stringWithFormat:@"%d kbps", bitRate/1000];			
		}
		else if ([value isKindOfClass:[NSArray class]])
		{
			formattedValue = [NSMutableString string];
			NSEnumerator *enumerator = [(NSArray*)value objectEnumerator];
			id obj;
			BOOL firstTime = YES;
			
			// calling [array description] was mangling japanese strings. Did this instead
			while (obj = [enumerator nextObject])
			{
				if ([obj isKindOfClass:[NSString class]])
				{
					if (!firstTime)
						[formattedValue appendString:@", "];
					
					[formattedValue appendString:obj];
					
					firstTime = NO;
				}
				else
				{
					// not strings, oh well, do this instead
					formattedValue = [[[value description] mutableCopy] autorelease];
					break;
				}
			}
		}
		else		
			formattedValue = [[[value description] mutableCopy] autorelease];
	}
	
	// remove \t \r & \n for nice printing
	[formattedValue replaceOccurrencesOfString:@"\t" withString:@"" options:0 range:NSMakeRange(0,[formattedValue length])];
	[formattedValue replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0,[formattedValue length])];
	[formattedValue replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0,[formattedValue length])];
	
	if ([formattedValue length])
		return [NSString stringWithString:formattedValue];
	
	return nil;
}	

+ (NSString*)localizedAttributeName:(NSString*)attributeName;
{		
	NSString* result = nil;
	
	// make thread safe, this is a mutable dictionary
	@synchronized([self class])
	{
		static NSMutableDictionary* shared = nil;
		
		if (!shared)
			shared = [[NSMutableDictionary alloc] init];
		
		result = [shared objectForKey:attributeName];
		if (!result)
		{
			CFStringRef cfString = MDSchemaCopyDisplayNameForAttribute((CFStringRef)attributeName);
			if (cfString)
			{
				result = [NSString stringWithString:(NSString*)cfString];
				CFRelease(cfString);
			}
						
			if (![result length])
			{
				result = attributeName;
				
				if ([result isEqualToString:@"kMDItemFSTypeCode"])
					result = @"Type";
				else if ([result isEqualToString:@"kMDItemFSCreatorCode"])
					result = @"Creator";
				else if ([result isEqualToString:@"kMDItemAttributeChangeDate"])
					result = @"Attributes";
				else if ([result isEqualToString:@"kMDItemFSFinderFlags"])
					result = @"Finder Flags";
				else if ([result isEqualToString:@"kMDItemContentType"])
					result = @"Content Type";
				else if ([result isEqualToString:@"kMDItemContentTypeTree"])
					result = @"Content Tree";
				else if ([result isEqualToString:@"kMDItemID"])
					result = @"Item ID";
				else if ([result isEqualToString:@"kMDItemCFBundleIdentifier"])
					result = @"Bundle Identifier";
				else if ([result isEqualToString:@"kMDItemSupportFileType"])
					result = @"Support Type";
				else 
					NSLog(@"%@", result);
			}
			
			if (result)
				[shared setObject:result forKey:attributeName];
		}
	}
	
	return result;
}

@end

@implementation NTMetadata (Private)

//---------------------------------------------------------- 
//  path 
//---------------------------------------------------------- 
- (NSString *)path
{
    return mPath; 
}

- (void)setPath:(NSString *)thePath
{
    if (mPath != thePath) {
        [mPath release];
        mPath = [thePath retain];
    }
}

- (void)setValueStrings:(NSArray *)theValueStrings
{
    if (mv_valueStrings != theValueStrings) {
        [mv_valueStrings release];
        mv_valueStrings = [theValueStrings retain];
    }
}

- (void)setAttributeNames:(NSArray *)theAttributeNames
{
    if (mv_attributeNames != theAttributeNames) 
	{
        [mv_attributeNames release];
        mv_attributeNames = [theAttributeNames retain];
    }
}

- (void)buildAttributesArrays;
{
	// this shit crashes if called from multiple threads!  (have more than one info view showing metadata and it crashes without this)
	@synchronized(self) {
		if (!mv_attributeNames && [self mdItemRef])
		{
			CFArrayRef inspectedRefAttributeNames;
			CFDictionaryRef inspectedRefAttributeValues;	
			
			inspectedRefAttributeNames = MDItemCopyAttributeNames([self mdItemRef]);
			inspectedRefAttributeValues = MDItemCopyAttributes([self mdItemRef],inspectedRefAttributeNames);;
			
			// inspectedRefAttributeValues returned nil on new iTunes, nil will crash the CFDictionaryGetValue function
			if (inspectedRefAttributeValues)
			{
				id value;
				NSString* displayName, *displayValue;
				CFStringRef attributeName;
				
				int i, cnt=inspectedRefAttributeNames ? CFArrayGetCount(inspectedRefAttributeNames) : 0;
				
				NSMutableArray* names = [NSMutableArray arrayWithCapacity:cnt];
				NSMutableArray* values = [NSMutableArray arrayWithCapacity:cnt];
				
				for (i=0;i<cnt;i++)
				{
					// attribute name
					attributeName = CFArrayGetValueAtIndex(inspectedRefAttributeNames, i);
					displayName = [NTMetadata localizedAttributeName:(NSString*)attributeName];
					
					// attribute value
					value = (id) CFDictionaryGetValue(inspectedRefAttributeValues, attributeName);
					displayValue = [self displayValue:(id)value forAttribute:(NSString*)attributeName];
					
					// must keep the arrays the same size, so check both for nil
					if (displayName && displayValue)
					{
						[names addObject:displayName];
						[values addObject:displayValue];
					}
				}
				
				[self setAttributeNames:names];
				[self setValueStrings:values];
			}
			
			if (inspectedRefAttributeNames)
				CFRelease(inspectedRefAttributeNames);
			
			if (inspectedRefAttributeValues)
				CFRelease(inspectedRefAttributeValues);
		}
	}
}

@end

@implementation NTMetadata (Utilities)

- (NSSize)imageSizeMD;
{
	NSSize imageSize = NSZeroSize;
	
	// this shit crashes if called from multiple threads!  (have more than one info view showing metadata and it crashes without this)
	@synchronized(self) {
		if ([self mdItemRef])
		{
			CFNumberRef heightRef = MDItemCopyAttribute([self mdItemRef], kMDItemPixelHeight);
			CFNumberRef widthRef = MDItemCopyAttribute([self mdItemRef], kMDItemPixelWidth);
			
			if (heightRef && widthRef)
				imageSize = NSMakeSize([(NSNumber*)widthRef floatValue], [(NSNumber*)heightRef floatValue]);
			
			if (heightRef)
				CFRelease(heightRef);
			if (widthRef)
				CFRelease(widthRef);
		}
	}
	
	return imageSize;
}

- (NSString*)imageSizeStringMD;
{
	NSString* result=@"";
	
	NSSize imageSize = [self imageSizeMD];
	
	if (!NSEqualSizes(NSZeroSize, imageSize))
		result = [[NTSizeFormatter sharedInstance] sizeString:imageSize];
	
	return result;
}

- (NSSize)imageDPIMD;
{
	NSSize imageSize = NSZeroSize;
	
	@synchronized(self) {
		if ([self mdItemRef])
		{
			// this shit crashes if called from multiple threads!  (have more than one info view showing metadata and it crashes without this)
			CFNumberRef heightRef = MDItemCopyAttribute([self mdItemRef], kMDItemResolutionHeightDPI);
			CFNumberRef widthRef = MDItemCopyAttribute([self mdItemRef], kMDItemResolutionWidthDPI);
			
			if (heightRef && widthRef)
				imageSize = NSMakeSize([(NSNumber*)widthRef floatValue], [(NSNumber*)heightRef floatValue]);
			
			if (heightRef)
				CFRelease(heightRef);
			if (widthRef)
				CFRelease(widthRef);
		}
	}
	
	return imageSize;
}

@end

