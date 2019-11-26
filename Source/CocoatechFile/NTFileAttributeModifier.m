//
//  NTFileAttributeModifier.m
//  CocoatechFile
//
//  Created by sgehrman on Wed Aug 08 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTFileAttributeModifier.h"
#include <sys/stat.h>

@implementation NTFileAttributeModifier

+ (BOOL)touch:(NTFileDesc*)desc;
{
    // need to force an update if the date is the same as now (this could be a sub second change)
    NSDate* currentDate = [desc modificationDate];
    NSDate* date = [NSDate date];

    if ([date isEqualToDate:currentDate])
    {
        NSTimeInterval secs = [date timeIntervalSinceReferenceDate];

        date = [NSDate dateWithTimeIntervalSinceReferenceDate:(secs - 1)];
    }

    return [NTFileAttributeModifier setModificationDate:date desc:desc];
}

+ (BOOL)touchAttributeModificationDate:(NTFileDesc*)desc;
{
    // need to force an update if the date is the same as now (this could be a sub second change)
    NSDate* currentDate = [desc attributeModificationDate];
    NSDate* date = [NSDate date];

    if ([date isEqualToDate:currentDate])
    {
        NSTimeInterval secs = [date timeIntervalSinceReferenceDate];

        date = [NSDate dateWithTimeIntervalSinceReferenceDate:(secs - 1)];
    }

    return [NTFileAttributeModifier setAttributeModificationDate:date desc:desc];
}

+ (BOOL)setAttributeModificationDate:(NSDate*)date desc:(NTFileDesc*)desc;
{
    FSCatalogInfo catalogInfo;

    if (!date)
        date = [NSDate date];

    catalogInfo.attributeModDate = [NSDate UTCDateTimeFromNSDate:date];

	OSErr err = FSSetCatalogInfo([desc FSRefPtr], kFSCatInfoAttrMod, &catalogInfo);
	
    return (err == noErr);
}

// pass nil for date to set to current date and time
+ (BOOL)setModificationDate:(NSDate*)date desc:(NTFileDesc*)desc;
{
    FSCatalogInfo catalogInfo;

    if (!date)
        date = [NSDate date];

    catalogInfo.contentModDate = [NSDate UTCDateTimeFromNSDate:date];

    OSErr err = FSSetCatalogInfo([desc FSRefPtr], kFSCatInfoContentMod, &catalogInfo);
	
	return (err == noErr);
}

+ (BOOL)setCreationDate:(NSDate*)date desc:(NTFileDesc*)desc;
{
    FSCatalogInfo catalogInfo;

    if (!date)
        date = [NSDate date];

    catalogInfo.createDate = [NSDate UTCDateTimeFromNSDate:date];

    return (FSSetCatalogInfo([desc FSRefPtr], kFSCatInfoCreateDate, &catalogInfo) == noErr);
}

@end
