//
//  NTFileSystemEventMessage.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/27/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTFileSystemEventMessage.h"
#import "NTFSSize.h"
#import "NTVolumeMgr.h"

@interface NTFileSystemEventMessage ()
@property (nonatomic, retain) NSString* path;
@property (nonatomic, assign) BOOL rescanSubdirectories;
@property (nonatomic, retain) NSString *relativePath_storage;
@property (nonatomic, retain) NSString *mountPoint_storage;
@end

@interface NTFileSystemEventMessage (Private)
- (void)updateRelativePath;
@end

@implementation NTFileSystemEventMessage

@synthesize path;
@synthesize rescanSubdirectories;
@synthesize relativePath_storage;
@synthesize mountPoint_storage;

+ (NTFileSystemEventMessage*)message:(NSString*)thePath rescanSubdirectories:(BOOL)theRescanSubdirectories;
{
	NTFileSystemEventMessage* result = [[NTFileSystemEventMessage alloc] init];
	
	result.path = thePath;
	result.rescanSubdirectories = theRescanSubdirectories;
	
	return [result autorelease];
}

- (void)dealloc;
{	
	self.path = nil;
	self.relativePath_storage = nil;
    self.mountPoint_storage = nil;

	[super dealloc];
}

- (void)updateMessage:(BOOL)theRescanSubdirectories
{
	if (!self.rescanSubdirectories && theRescanSubdirectories)
		self.rescanSubdirectories = YES;
}

- (NSString*)relativePath;
{
	if (!self.relativePath_storage)
		[self updateRelativePath];
	
	return self.relativePath_storage;
}

- (NSString*)mountPoint;
{
	if (!self.mountPoint_storage)
		[self updateRelativePath];
	
	return self.mountPoint_storage;	
}

@end

@implementation NTFileSystemEventMessage (Private)

- (void)updateRelativePath;
{
	NSString* outMountPoint;
	
	self.relativePath_storage = [[NTVolumeMgr sharedInstance] relativePath:self.path outMountPoint:&outMountPoint];
	self.mountPoint_storage = outMountPoint;
}

- (BOOL)isEqual:(NTFileSystemEventMessage*)right;
{
	if (self.rescanSubdirectories == right.rescanSubdirectories)
		return [right.path isEqualToString:self.path];

	return NO;
}

- (NSUInteger)hash;
{
	NSUInteger result = [self.path hash];
	
	if (self.rescanSubdirectories)
		result += 512;
	
	return result;
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"path:%@ flag:%@", self.path, (self.rescanSubdirectories) ? @"YES":@"NO"];
}

@end

