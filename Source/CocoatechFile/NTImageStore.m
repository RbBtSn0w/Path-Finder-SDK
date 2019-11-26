//
//  NTImageStore.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 9/6/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTImageStore.h"
#import "NTIconStore.h"
#import "NTIcon.h"
#import "NSImage-CocoatechFile.h"
#import "NTPathUtilities.h"

@interface NTImageStore ()
@property (nonatomic, retain) NSMutableDictionary *images;
@property (retain) NSBundle *coreTypesBundle;

@property (retain) NSImage* countBadgeImage;
@property (retain) NSImage* countBadgeImage3;
@property (retain) NSImage* countBadgeImage4;
@property (retain) NSImage* countBadgeImage5;
@end

@interface NTImageStore (Private)
- (NSImage*)imageForKey:(NSString*)theKey;
- (void)setImage:(NSImage*)theImage forKey:(NSString*)theKey;
- (NSImage*)imageForIconSelector:(SEL)theSelector icon:(NTIcon*)theIcon;
- (NSImage*)imageForSelector:(SEL)theSelector;
- (NTFileDesc*)iconFromSystemIconsBundleWithName:(NSString*)iconName;
- (NSImage *)imageInBundle:(NSString*)name;
@end

@implementation NTImageStore

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize images;
@synthesize countBadgeImage;
@synthesize countBadgeImage3;
@synthesize countBadgeImage4;
@synthesize countBadgeImage5;
@synthesize coreTypesBundle;

- (id)init;
{
	self = [super init];
	
	self.images = [NSMutableDictionary dictionary];
	self.coreTypesBundle = [NSBundle bundleWithPath:@"/System/Library/CoreServices/CoreTypes.bundle"];

	return self;
}

- (void)dealloc;
{
	self.coreTypesBundle = nil;
	self.images = nil;
    self.countBadgeImage = nil;
    self.countBadgeImage3 = nil;
    self.countBadgeImage4 = nil;
    self.countBadgeImage5 = nil;
	
	[super dealloc];
}

- (NSImage *)imageWithName:(NSString*)name; // images in CoreTypes.bundle.  for example: ToolbarPicturesFolderIcon
{
	NTFileDesc* desc = [self iconFromSystemIconsBundleWithName:name];
	
	return [[[NSImage alloc] initWithContentsOfURL:[desc URL]] autorelease];
}

- (NSImage*)imageForSystemType:(OSType)type size:(NSUInteger)size
{
	NTIcon* icon = [NTIS iconForSystemType:type];
	
	return [icon imageForSize:size];
}

- (NSImage *)aliasBadge;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)lockBadge;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)makeFolderBadge;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)appleScriptBadge;
{
	return [self imageForIconSelector:_cmd icon:[NTIS appleScriptBadge]];
}

- (NSImage *)computerIcon;
{
	return [NSImage imageNamed:NSImageNameComputer];
}

- (NSImage *)documentIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS documentIcon]];
}

- (NSImage *)textDocumentIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)clippingsDocumentIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS clippingsDocumentIcon]];
}

- (NSImage *)folderIcon;
{
	return [NSImage imageNamed:NSImageNameFolder];
}

- (NSImage *)trashIcon;
{
	return [NSImage imageNamed:NSImageNameTrashEmpty];
}

- (NSImage *)trashFullIcon;
{
	return [NSImage imageNamed:NSImageNameTrashFull];
}

- (NSImage *)ejectIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS ejectIcon]];
}

- (NSImage *)backwardsIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS backwardsIcon]];
}

- (NSImage *)forwardsIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS forwardsIcon]];
}

- (NSImage *)connectToIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS connectToIcon]];
}

- (NSImage *)iDiskIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS iDiskIcon]];
}

- (NSImage *)iDiskPublicIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS iDiskPublicIcon]];
}

- (NSImage *)hardDiskIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS hardDiskIcon]];
}

- (NSImage *)previewIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)iTunesIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)colorPanelIcon;
{
	return [NSImage imageNamed:NSImageNameColorPanel];
}

- (NSImage *)networkIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS networkIcon]];
}

- (NSImage *)fileServerIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS fileServerIcon]];
}

- (NSImage *)macFileServerIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)genericPCServerIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)CDROMIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS CDROMIcon]];
}

- (NSImage *)multipleFilesIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)smallMultipleFilesIcon;
{
	return [NSImage imageNamed:NSImageNameMultipleDocuments];
}

- (NSImage *)spotlightIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)homeIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS homeIcon]];
}

- (NSImage *)favoritesIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS favoritesIcon]];
}

- (NSImage *)deleteIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS deleteIcon]];
}

- (NSImage *)finderIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS finderIcon]];
}

- (NSImage *)desktopIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)windowIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)publicIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)picturesIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)makeFolderIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)makeFileIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)musicIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)moviesIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)infoIcon;
{
	return [NSImage imageNamed:NSImageNameInfo];
}

- (NSImage *)findIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)documentsIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)applicationsIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)noWriteIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS noWriteIcon]];
}

- (NSImage *)writeIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)drawerIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)burnIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS burnIcon]];
}

- (NSImage *)eraseIcon;
{
	return [NSImage imageNamed:DREraseIcon];
}

- (NSImage *)recentItemsIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS recentItemsIcon]];
}

- (NSImage *)libraryIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)sitesIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)downloadsIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)utilitiesIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)stopIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)zoomOutIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)zoomInIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)zoomToActualSizeIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)nextPageIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)previousPageIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)preferencesIcon;
{
	return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSImage *)applicationIcon;
{
	return [self imageForIconSelector:_cmd icon:[NTIS applicationIcon]];
}

- (NSImage *)screenSharingIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)screenSharingNetworkIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)rotateLeftIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)rotateRightIcon;
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)miniFile
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)miniFolder
{
	return [self imageForSelector:_cmd];
}

- (NSImage *)miniApplication
{
	return [self imageForSelector:_cmd];
}

- (NSImage*)openFolderImage;
{
	return [self imageForSelector:_cmd];
}

- (NSImage*)unknownFSObjectImage;
{
	return [self imageForSelector:_cmd];
}

- (NSImage*)quickLookImage;
{
    return [NSImage imageNamed:NSImageNameQuickLookTemplate];
}

- (NSImage*)slideshowImage;
{
    return [NSImage imageNamed:NSImageNameSlideshowTemplate];
}

- (NSImage*)coverflowImage;
{
    return [NSImage imageNamed:NSImageNameFlowViewTemplate];
}

- (NSImage*)reloadImage;
{
    return [NSImage imageNamed:NSImageNameRefreshTemplate];
}

- (NSImage*)countBadgeImage:(int)numDigits;
{
	NSString* imageName = nil;
	NSString* path = nil;
	
	if (numDigits < 3)
	{
		@synchronized(self) {
			if (!self.countBadgeImage)
			{
				imageName = @"countBadge.png";
				path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
				if (path)
					self.countBadgeImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
			}			
		}
		
		return self.countBadgeImage;
	}
	if (numDigits == 3)
	{
		@synchronized(self) {
			if (!self.countBadgeImage3)
			{
				imageName = @"countBadge3.png";
				path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
				if (path)
					self.countBadgeImage3 = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
			}		
		}
		return self.countBadgeImage3;
	}
	if (numDigits == 4)
	{
		@synchronized(self) {
			if (!self.countBadgeImage4)
			{
				imageName = @"countBadge4.png";
				path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
				if (path)
					self.countBadgeImage4 = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
			}
		}
		
		return self.countBadgeImage4;
	}
	
	@synchronized(self) {
		if (!self.countBadgeImage5)
		{
			imageName = @"countBadge5.png";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			if (path)
				self.countBadgeImage5 = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
		}
	}
	
    return self.countBadgeImage5; 
}

@end

@implementation NTImageStore (Private)

- (NSImage*)imageForSelector:(SEL)theSelector;
{
	NSString* theKey = NSStringFromSelector(theSelector);
	NSImage* result = [self imageForKey:theKey];
	
	if (!result)
	{
		if ([theKey isEqualToString:@"multipleFilesIcon"])
		{
			// [NSImage imageNamed:NSImageNameMultipleDocuments]
			NSImage* theImage = [[self documentIcon] imageWithSetSize:384];
			
			NTImageMaker *imageMaker = [NTImageMaker maker:NSMakeSize(512, 512)];
			[imageMaker lockFocus];
			{
				int offsetX = 40;
				int offsetY = 18;
				int start = (512-384) / 2;
				
				[theImage compositeToPoint:NSMakePoint(start+offsetX, start+offsetY) operation:NSCompositeSourceOver fraction:1];
				[theImage compositeToPoint:NSMakePoint(start, start) operation:NSCompositeSourceOver fraction:1];
				[theImage compositeToPoint:NSMakePoint(start-offsetX, start-offsetY) operation:NSCompositeSourceOver fraction:1];
			}
			result = [imageMaker unlockFocus];				
		}
		else if ([theKey isEqualToString:@"makeFolderBadge"])
			result = [self imageWithName:@"NewFolderBadgeIcon"];
		else if ([theKey isEqualToString:@"makeFolderIcon"])
		{
			NSImage *newFolder = [[self folderIcon] imageWithSetSize:128];
			result = [newFolder imageWithBadge:[self makeFolderBadge]];
		}
		else if ([theKey isEqualToString:@"makeFileIcon"])
		{
			NSImage *newFile = [[self documentIcon] imageWithSetSize:128];
			result = [newFile imageWithBadge:[self makeFolderBadge]];
		}
		else if ([theKey isEqualToString:@"applicationsIcon"])
			result = [self imageWithName:@"ToolbarAppsFolderIcon"];
		else if ([theKey isEqualToString:@"documentsIcon"])
			result = [self imageWithName:@"ToolbarDocumentsFolderIcon"];
		else if ([theKey isEqualToString:@"findIcon"])
			result = [self imageWithName:@"MagnifyingGlassIcon"];
		else if ([theKey isEqualToString:@"moviesIcon"])
			result = [self imageWithName:@"ToolbarMovieFolderIcon"];
		else if ([theKey isEqualToString:@"musicIcon"])
			result = [self imageWithName:@"ToolbarMusicFolderIcon"];
		else if ([theKey isEqualToString:@"picturesIcon"])
			result = [self imageWithName:@"ToolbarPicturesFolderIcon"];
		else if ([theKey isEqualToString:@"publicIcon"])
			result = [self imageWithName:@"ToolbarPublicFolderIcon"];
		else if ([theKey isEqualToString:@"genericPCServerIcon"])
			result = [self imageWithName:@"public.generic-pc"];
		else if ([theKey isEqualToString:@"windowIcon"])
			result = [self imageWithName:@"GenericWindowIcon"];
		else if ([theKey isEqualToString:@"libraryIcon"])
			result = [self imageWithName:@"ToolbarLibraryFolderIcon"];
		else if ([theKey isEqualToString:@"downloadsIcon"])
			result = [self imageWithName:@"ToolbarDownloadsFolderIcon"];
		else if ([theKey isEqualToString:@"utilitiesIcon"])
			result = [self imageWithName:@"ToolbarUtilitiesFolderIcon"];
		else if ([theKey isEqualToString:@"desktopIcon"])
			result = [self imageWithName:@"ToolbarDesktopFolderIcon"];
		else if ([theKey isEqualToString:@"aliasBadge"])
			result = [self imageWithName:@"AliasBadgeIcon"];
		else if ([theKey isEqualToString:@"lockBadge"])
			result = [self imageWithName:@"LockedBadgeIcon"];
		else if ([theKey isEqualToString:@"sitesIcon"])
			result = [self imageWithName:@"ToolbarSitesFolderIcon"];
		else if ([theKey isEqualToString:@"macFileServerIcon"])
			result = [self imageWithName:@"com.apple.mac"];
		else if ([theKey isEqualToString:@"drawerIcon"])
			result = [self imageInBundle:@"drawer_local.icns"];
		else if ([theKey isEqualToString:@"textDocumentIcon"])
			result = [self imageInBundle:@"textDocument.icns"];
		else if ([theKey isEqualToString:@"writeIcon"])
			result = [self imageInBundle:@"writeIcon.icns"];
		else if ([theKey isEqualToString:@"screenSharingIcon"])
			result = [self imageInBundle:@"screenSharing.icns"];
		else if ([theKey isEqualToString:@"screenSharingNetworkIcon"])
			result = [self imageInBundle:@"screenSharingNetwork.tif"];
		else if ([theKey isEqualToString:@"spotlightIcon"])
			result = [self imageInBundle:@"spotlight.icns"];
		else if ([theKey isEqualToString:@"stopIcon"])
			result = [self imageInBundle:@"stop_local.icns"];
		else if ([theKey isEqualToString:@"nextPageIcon"])
			result = [self imageInBundle:@"nextPage_local.icns"];
		else if ([theKey isEqualToString:@"previousPageIcon"])
			result = [self imageInBundle:@"previousPage_local.icns"];
		else if ([theKey isEqualToString:@"zoomInIcon"])
			result = [self imageInBundle:@"zoomIn_local.icns"];
		else if ([theKey isEqualToString:@"zoomOutIcon"])
			result = [self imageInBundle:@"zoomOut_local.icns"];
		else if ([theKey isEqualToString:@"zoomToActualSizeIcon"])
			result = [self imageInBundle:@"zoomToActualSize_local.icns"];
		else if ([theKey isEqualToString:@"rotateLeftIcon"])
			result = [self imageInBundle:@"RotateLeftToolbarImage.icns"];
		else if ([theKey isEqualToString:@"rotateRightIcon"])
			result = [self imageInBundle:@"RotateRightToolbarImage.icns"];		
		else if ([theKey isEqualToString:@"previewIcon"])
		{
			NSString* path = [NTPathUtilities fullPathForApplication:@"Preview.app"];
			if (path)
			{
				NTFileDesc *desc = [NTFileDesc descResolve:path];
				
				if ([desc isValid])
					result = [desc iconImage];
			}			
		}
		else if ([theKey isEqualToString:@"iTunesIcon"])
		{
			NSString* path = [NTPathUtilities fullPathForApplication:@"iTunes.app"];
			if (path)
			{
				NTFileDesc *desc = [NTFileDesc descResolve:path];
				
				if ([desc isValid])
					result = [desc iconImage];
			}			
		}
		else if ([theKey isEqualToString:@"miniFile"])
			result = [[self documentIcon] imageWithSetSize:12];
		else if ([theKey isEqualToString:@"miniFolder"])
			result = [[self folderIcon] imageWithSetSize:12];
		else if ([theKey isEqualToString:@"miniApplication"])
			result = [[self applicationIcon] imageWithSetSize:12];
		else if ([theKey isEqualToString:@"openFolderImage"])
			result = [self imageWithName:@"OpenFolderIcon"];
		else if ([theKey isEqualToString:@"unknownFSObjectImage"])
			result = [self imageWithName:@"UnknownFSObjectIcon"];
		
		if (result)
			[self setImage:result forKey:theKey];
		else
			NSLog(@"no image");
	}
	
	return result;
}

- (NSImage*)imageForIconSelector:(SEL)theSelector icon:(NTIcon*)theIcon
{
	NSString* theKey = NSStringFromSelector(theSelector);
	NSImage* result = [self imageForKey:theKey];
	
	if (!result)
	{
		result = [theIcon image];
		
		if (result)
			[self setImage:result forKey:theKey];
		else
			NSLog(@"no image");
	}
	
	return result;
}

- (NSImage*)imageForKey:(NSString*)theKey;
{
	NSImage* result = nil;
	
	@synchronized(self) {
		result = [self.images objectForKey:theKey];
		
		[[result retain] autorelease];
	}
	
	return result;
}

- (void)setImage:(NSImage*)theImage forKey:(NSString*)theKey;
{
	@synchronized(self) {
		[self.images setObject:theImage forKey:theKey];
	}
}

- (NTFileDesc*)iconFromSystemIconsBundleWithName:(NSString*)iconName;
{
	NSString* path = [self.coreTypesBundle pathForImageResource:iconName];
	NTFileDesc* desc;
	
	if (path)
	{
		desc = [NTFileDesc descNoResolve:path];
		
		if (desc && [desc isValid])
			return desc;
	}
	
    return nil;
}

- (NSImage *)imageInBundle:(NSString*)imageName;
{
	NSString* path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
	NTFileDesc* desc = [NTFileDesc descNoResolve:path];

	return [[[NSImage alloc] initWithContentsOfURL:[desc URL]] autorelease];
}

@end

