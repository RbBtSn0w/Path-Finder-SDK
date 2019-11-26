//
//  NTVolumeMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTVolumeMgr.h"
#import "NTVolumeSpec.h"
#import "NTVolumeNotificationMgr.h"
#import "NTVolumeMgrState.h"
#import "NTVolumeModifiedWatcher.h"

@interface NTVolumeMgr ()
@property (retain, nonatomic) NSArray *mountPoints;
@property (retain, nonatomic) NTVolumeMgrState* state;
@property (retain, nonatomic) NSArray* volumeSpecArray;
@property (retain, nonatomic) NSDictionary* volumeSpecDictionary;
@end

@interface NTVolumeMgr (Private)
- (void)refreshStateIfInvalid;
- (NSString*)mountPointForPath:(NSString*)thePath;

+ (NSMutableArray*)mountedVolumeSpecsUsingCocoa;
+ (NSMutableArray*)mountedVolumeSpecsUsingCarbon;
+ (NSArray*)mountedVolumeSpecsUsingSnowLeopard;

// returns NTVolumeSpec
+ (NSArray*)mountedVolumeSpecs;
@end

@interface NTVolumeMgr (MountPointsPrivate)
- (NSString*)newRelativePath:(NSString*)thePath outMountPoint:(NSString**)outMountPoint;
- (NSString*)oldRelativePath:(NSString*)thePath outMountPoint:(NSString**)outMountPoint;
@end

@implementation NTVolumeMgr

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize state, mountPoints;
@synthesize volumeSpecArray;
@synthesize volumeSpecDictionary;

- (id)init;
{
	self = [super init];
	
	// start this up
	[self performDelayedSelector:@selector(startupVolumeModifiedWatcher) withObject:nil];
	
	return self;
}

- (void)dealloc;
{
	self.state = nil;
	self.volumeSpecArray = nil;
	self.volumeSpecDictionary = nil;
	self.mountPoints = nil;
	
	[super dealloc];
}

- (NSArray*)volumes;
{
	NSMutableArray* result = [NSMutableArray array];
	
	for (NTVolumeSpec *vDesc in [self volumeSpecs])
		[result addObjectIf:[vDesc mountPoint]];
	
	return result;
}

- (NSArray*)volumeSpecs;
{
	NSArray *result = nil;
	
	@synchronized(self)	{
		[self refreshStateIfInvalid];
				
		result = [NSArray arrayWithArray:self.volumeSpecArray];
	}
	
	return result;
}

- (NSArray*)freshVolumeSpecs;
{
	return [NTVolumeMgr mountedVolumeSpecs];
}

- (NTVolumeSpec *)volumeSpecForRefNum:(FSVolumeRefNum)vRefNum;
{
	NSNumber* key = [NSNumber numberWithShort:vRefNum];
	NTVolumeSpec* result;
	
	@synchronized(self)	{
		[self refreshStateIfInvalid];
		
		result = [[[self.volumeSpecDictionary objectForKey:key] retain] autorelease];
		if (!result)
		{
			result = [NTVolumeSpec volumeWithRefNum:vRefNum];
			if (result)
			{
				NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:self.volumeSpecDictionary];
				[dict setObject:result forKey:key];
				
				self.volumeSpecDictionary = [NSDictionary dictionaryWithDictionary:dict];
			}
		}
	}
	
	return result;
}

- (NSString*)relativePath:(NSString*)thePath outMountPoint:(NSString**)outMountPoint;
{
	NSString* theMountPoint = [self mountPointForPath:thePath];
	
	NSString* result = [thePath stringByRemovingPrefix:theMountPoint];
	
	if (![theMountPoint isEqualToString:@"/"])
	{
		// mountPoint doesn't end in /, so remove that
		result = [result stringByRemovingPrefix:@"/"];
	}
	
	if (outMountPoint)
		*outMountPoint = theMountPoint;
	
	return result;
}

@end

@implementation NTVolumeMgr (Private)

- (void)startupVolumeModifiedWatcher;
{
	[NTVolumeModifiedWatcher sharedInstance];
}

// returns NTVolumeSpec
+ (NSArray*)mountedVolumeSpecs;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
	
	NSMutableArray *cocoaVolumes = [self mountedVolumeSpecsUsingCocoa];
	for (NTVolumeSpec *theSpec in cocoaVolumes)
	{
		// expand drives never appear in the Cocoa list, but if the bug is fixed at some point, we don't want to break, so only copy non expand drives
		if (![theSpec isExpandrive])
			[result addObjectIf:theSpec];
	}
	
	NSMutableArray* expandDrives = [self mountedVolumeSpecsUsingCarbon];
	for (NTVolumeSpec *theSpec in expandDrives)
	{
		// add only expandrives since they show up in the carbon list, but don't add anything else to avoid issues
		if ([theSpec isExpandrive])
			[result addObjectIf:theSpec];
	}
	
	return result;
}

// (### CODE DOESNT WORK IN ALL CASES ###)
+ (NSArray*)mountedVolumeSpecsUsingSnowLeopard;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
	
	NSArray *volumeURLs = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:nil options:NSVolumeEnumerationSkipHiddenVolumes];
	for (NSURL *mountPointURL in volumeURLs)
	{
		NTFileDesc* desc = [NTFileDesc descNoResolve:[mountPointURL path]];
		
		if ([desc isValid])
		{
			NTVolumeSpec* volumeSpec = [NTVolumeSpec volumeWithMountPoint:desc];
			
			if ([volumeSpec isUserVolume])  // this might be unecessary 
				[result addObjectIf:volumeSpec];
		}
	}	
	
	return result;	
}

+ (NSMutableArray*)mountedVolumeSpecsUsingCocoa;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
	
	NSArray *mountedVols = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]; 
	for (NSString *mountPoint in mountedVols)
	{
		NTFileDesc* desc = [NTFileDesc descNoResolve:mountPoint];
		
		if ([desc isValid])
		{
			NTVolumeSpec* volumeSpec = [NTVolumeSpec volumeWithMountPoint:desc];
			
			if ([volumeSpec isUserVolume])
				[result addObjectIf:volumeSpec];
		}
	}	
	
	return result;
}

+ (NSMutableArray*)mountedVolumeSpecsUsingCarbon;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
	
	FSRef ref;
	OSErr err=noErr;
	
	for (ItemCount volumeIndex = 1; err == noErr || err != nsvErr; volumeIndex++) 
	{
		err = FSGetVolumeInfo(kFSInvalidVolumeRefNum,
							  volumeIndex,
							  NULL,
							  kFSVolInfoNone,
							  NULL,
							  NULL,
							  &ref); 
		
		if (err == noErr)
		{
			NTFileDesc* desc = [NTFileDesc descFSRef:&ref];
			
			if ([desc isValid])
			{
				NTVolumeSpec* volumeSpec = [NTVolumeSpec volumeWithMountPoint:desc];
				
				if ([volumeSpec isUserVolume])
					[result addObjectIf:volumeSpec];
			}				
		}
	}	
	
	return result;
}

- (void)refreshStateIfInvalid;
{
	if (self.state && self.state.changed)
	{		
		self.state = nil;
		self.volumeSpecDictionary = nil;
		self.volumeSpecArray = nil;
		self.mountPoints = nil;
	}
	
	if (!self.state)
	{
		NSMutableDictionary* volumeSpecDict = [NSMutableDictionary dictionary];
		NSMutableArray* theMountPoints = [NSMutableArray array];

		self.state = [NTVolumeMgrState state];
		
		NSArray *volumeSpecs = [NTVolumeMgr mountedVolumeSpecs];
		for (NTVolumeSpec* volumeSpec in volumeSpecs)
		{
			[volumeSpecDict setObject:volumeSpec forKey:[NSNumber numberWithInt:[volumeSpec volumeRefNum]]];	
			
			[theMountPoints addObjectIf:[volumeSpec mountPath]];
		}
		
		self.mountPoints = [NSArray arrayWithArray:theMountPoints];
		self.volumeSpecDictionary = [NSDictionary dictionaryWithDictionary:volumeSpecDict];
		self.volumeSpecArray = volumeSpecs;
	}		
}

- (NSString*)mountPointForPath:(NSString*)thePath;
{
	NSString* result = @"/";
	NSArray* mpoints = nil;
	
	@synchronized(self) {
		[self refreshStateIfInvalid];
		
		for (NSString* theMP in self.mountPoints)
		{
			if ([thePath hasPrefix:theMP])
			{
				if ([theMP length] > [result length])
					result = theMP;
			}
		}
	}
	
	return result;
}

@end

