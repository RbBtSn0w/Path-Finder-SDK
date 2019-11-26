//
//  NTIconStore.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Thu Aug 15 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTIcon;

#define NTIS ((NTIconStore*)[NTIconStore sharedInstance])

@interface NTIconStore : NTSingletonObject
{
	NSMutableDictionary* systemIcons;
}

- (NTIcon *)iconForSystemType:(OSType)iconType;

- (NTIcon*)appleScriptBadge;
- (NTIcon*)documentIcon;
- (NTIcon*)applicationIcon;
- (NTIcon*)noWriteIcon;
- (NTIcon*)openFolderIcon;
- (NTIcon*)ejectIcon;
- (NTIcon*)backwardsIcon;
- (NTIcon*)forwardsIcon;
- (NTIcon*)connectToIcon;
- (NTIcon*)fileServerIcon;
- (NTIcon*)networkIcon;
- (NTIcon*)CDROMIcon;
- (NTIcon*)iDiskIcon;
- (NTIcon*)iDiskPublicIcon;
- (NTIcon*)hardDiskIcon;
- (NTIcon*)homeIcon;
- (NTIcon*)favoritesIcon;
- (NTIcon*)deleteIcon;
- (NTIcon*)finderIcon;
- (NTIcon*)burnIcon;
- (NTIcon*)recentItemsIcon;
- (NTIcon*)clippingsDocumentIcon;
@end




