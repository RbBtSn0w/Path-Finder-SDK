//
//  NTIconStore.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Thu Aug 15 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTIconStore.h"
#import "NTIcon.h"
#import "NTIconFamily.h"
#import "NTPathUtilities.h"
#import "NSImage-CocoatechFile.h"

@interface NTIconStore ()
@property (nonatomic, retain) NSMutableDictionary* systemIcons;
@end

@interface NTIconStore (Private)
- (NTIcon *)iconForType:(OSType)iconType creator:(OSType)creator;
@end

@implementation NTIconStore

@synthesize systemIcons;

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];
	
    self.systemIcons = [NSMutableDictionary dictionaryWithCapacity:50];	
		
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.systemIcons = nil;
	
    [super dealloc];
}

- (NTIcon *)iconForSystemType:(OSType)iconType;
{
    return [self iconForType:iconType creator:kSystemIconsCreator];
}

- (NTIcon*)appleScriptBadge;
{
    return [self iconForSystemType:kAppleScriptBadgeIcon];
}

- (NTIcon*)documentIcon;
{    
    return [self iconForSystemType:kGenericDocumentIcon];
}

- (NTIcon*)applicationIcon;
{
    return [self iconForSystemType:kGenericApplicationIcon];
}

- (NTIcon*)noWriteIcon;
{
    return [self iconForSystemType:kNoWriteIcon];
}

- (NTIcon*)openFolderIcon;
{
    return [self iconForSystemType:kOpenFolderIcon];
}

- (NTIcon*)ejectIcon;
{
    return [self iconForSystemType:kEjectMediaIcon];
}

- (NTIcon*)backwardsIcon;
{
    return [self iconForSystemType:kBackwardArrowIcon];
}

- (NTIcon*)forwardsIcon;
{
    return [self iconForSystemType:kForwardArrowIcon];
}

- (NTIcon*)connectToIcon;
{
    return [self iconForSystemType:kConnectToIcon];
}

- (NTIcon*)fileServerIcon;
{
    return [self iconForSystemType:kGenericFileServerIcon];
}

- (NTIcon*)networkIcon;
{
    return [self iconForSystemType:kGenericNetworkIcon];
}

- (NTIcon*)CDROMIcon;
{
    return [self iconForSystemType:kGenericCDROMIcon];
}

- (NTIcon*)iDiskIcon;
{
    return [self iconForSystemType:kGenericIDiskIcon];
}

- (NTIcon*)iDiskPublicIcon;
{
    return [self iconForSystemType:kUserIDiskIcon];
}

- (NTIcon*)hardDiskIcon;
{
    return [self iconForSystemType:kGenericHardDiskIcon];    
}

- (NTIcon*)homeIcon;
{
    return [self iconForSystemType:kToolbarHomeIcon];
}

- (NTIcon*)favoritesIcon;
{
    return [self iconForSystemType:kToolbarFavoritesIcon];
}

- (NTIcon*)deleteIcon;
{
    return [self iconForSystemType:kToolbarDeleteIcon];
}

- (NTIcon*)finderIcon;
{
    return [self iconForSystemType:kFinderIcon];
}

- (NTIcon*)burnIcon;
{
    return [self iconForSystemType:kBurningIcon];
}

- (NTIcon*)recentItemsIcon;
{
    return [self iconForSystemType:kRecentItemsIcon];
}

- (NTIcon*)clippingsDocumentIcon;
{
    return [self iconForSystemType:kClippingTextTypeIcon];
}

@end

@implementation NTIconStore (Private)

- (NTIcon *)iconForType:(OSType)iconType creator:(OSType)creator;
{
    NTIcon* result=nil;
    OSStatus err;
    IconRef iconRef;
	NSNumber* theKey = [NSNumber numberWithUnsignedInt:iconType];
	
	// thread protect the mutable arrays
	@synchronized(self) {
		result = [self.systemIcons objectForKey:theKey];
		if (!result)
		{
			err = GetIconRef(kOnSystemDisk, creator, iconType, &iconRef);
			if (!err)
			{
				result = [NTIcon iconWithRef:iconRef];
				ReleaseIconRef(iconRef);
			}
			
			// add to cache
			if (result)
				[self.systemIcons setObject:result forKey:theKey];			
		}			
	}
	
    return result;
}

@end



