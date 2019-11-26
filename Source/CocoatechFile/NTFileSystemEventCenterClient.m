//
//  NTFileSystemEventCenterClient.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/23/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTFileSystemEventCenterClient.h"
#import "NTFileSystemEventCenter.h"
#import "NTVolume.h"
#import "NTVolumeMgrState.h"
#import "NTFileSystemEventMessage.h"
#import "NTFSEventClient.h"
#import "NTFileEnvironment.h"
#import "NTVolumeMgr.h"

@interface NTFileSystemEventCenterClient ()
@property (nonatomic, retain) NSString *relativePath;
@property (nonatomic, retain) NSString *comparePath;
@property (nonatomic, retain) NTMessageProxy *delegateProxy;
@property (nonatomic, retain) NSString *volumeUniqueID;
@property (nonatomic, retain) NTFileDesc* folder;
@property (nonatomic, retain) NSMutableArray* pendingMessages;
@property (nonatomic, assign) BOOL caseSensitive;
@property (nonatomic, assign) BOOL includeSubfolders;
@property (nonatomic, assign) BOOL isReadOnly;
@property (nonatomic, assign) BOOL sentPendingMessage;
@property (nonatomic, retain) NSNumber* uniqueID;
@end

@implementation NTFileSystemEventCenterClient

// need to listen for volume renames and folder renames to double check to see if path changed
// if path changed, reset the client and register to the eventCenter

@synthesize delegateProxy;
@synthesize relativePath;
@synthesize volumeUniqueID,isReadOnly, includeSubfolders, caseSensitive, comparePath, folder;
@synthesize uniqueID, pendingMessages, sentPendingMessage;

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{		
    self.relativePath = nil;
	self.delegateProxy = nil;
	self.volumeUniqueID = nil;
	self.comparePath = nil;
	self.folder = nil;
	self.uniqueID = nil;
	self.pendingMessages = nil;
	
    [super dealloc];
}

+ (NTFileSystemEventCenterClient*)client:(NTMessageProxy*)theDelegateProxy 
								  folder:(NTFileDesc*)theFolder 
					   includeSubfolders:(BOOL)includeSubfolders 
								uniqueID:(NSNumber*)uniqueID;
{
	if (![theFolder isComputer] &&
		[theFolder isReadOnly] && 
		[theFolder isLocalFileSystem])
	{
		// return nil if folder is readOnly, locked etc. 
		// Network volumes could be writable by others, so allow that
		return nil;
	}
	
	NTFileSystemEventCenterClient* result = [[NTFileSystemEventCenterClient alloc] init];
	result.delegateProxy = theDelegateProxy;
	result.includeSubfolders = includeSubfolders;
	result.folder = theFolder;
	result.uniqueID = uniqueID;
	
	return [result autorelease];
}

@end

@implementation NTFileSystemEventCenterClient (InternalAccessOnly)

// called on an async dispatch queue
- (void)notify:(NTFileSystemEventMessage*)theMessage;
{
	// computer level sends nil, put something in there
	if (!theMessage)
		theMessage = [NTFileSystemEventMessage message:@"" rescanSubdirectories:NO];
	
	@synchronized(self) {
		if (!self.pendingMessages)
			self.pendingMessages = [NSMutableArray array];
		
		// don't add duplicates
		if (![self.pendingMessages containsObject:theMessage])
			[self.pendingMessages addObject:theMessage];
	}
	
	if (!self.sentPendingMessage)
	{
		self.sentPendingMessage = YES;
		
		// perform after delay doesn't work on a thread
		dispatch_async(dispatch_get_main_queue(), ^{
			@try {
				[self performSelector:@selector(notifyOnMainThread) withObject:nil];
			}
			@catch (NSException * e) {
				NSLog(@"notify exception: %@", e);
			}
			@finally {
			}
		});
	}
}

- (void)notifyOnMainThread;
{	
	self.sentPendingMessage = NO;
	
	NSArray* theMessages = nil;
	@synchronized(self) {		
		theMessages = [NSArray arrayWithArray:self.pendingMessages];
		self.pendingMessages = nil;
	}
	
	if ([theMessages count])
	{
		if (FENV(logFSEvents))
			[[NTFileEnvironment sharedInstance] notify_FSEvent:@"sending" eventInfo:[theMessages description]];

		[self.delegateProxy notify:[NSDictionary dictionaryWithObjectsAndKeys:self.uniqueID, kFSEventClient_uniqueIDKey, theMessages, kFSEventClient_messagesKey, nil]];
	}
}

- (void)initializeValues;
{
	if ([self.folder isComputer])
	{
		if (includeSubfolders)
			NSLog(@"includeSubfolders not supported for computer level");
		
		self.volumeUniqueID = kNTComputerEventClient;
		self.relativePath = kNTComputerEventClient;
		self.comparePath = kNTComputerEventClient;
		self.caseSensitive = YES;  // should be fine without this, but just avoid any chance of the code trying to lowercase this string
		self.isReadOnly = YES;
	}
	else
	{		
		NTVolume* theVolume = [self.folder volume];
		
		self.isReadOnly = [theVolume isReadOnly];

		NSString* thePath = [self.folder path];
		NSString* theMountPoint;
		self.relativePath = [[NTVolumeMgr sharedInstance] relativePath:thePath outMountPoint:&theMountPoint];
		self.volumeUniqueID = [NTFileSystemEventCenter volumeIDForMountPoint:theMountPoint];

		// ## file vault issue ##
		// This was failing for fileValult.  The files volume is differnet than the "/" mount point we would use when we are matching paths.  filevault mountpoint looks like /Users/userName/ for items in the home folder
		// so we use the "/" mount point in this case
		//
		// self.volumeUniqueID = [theVolume volumeUniqueID];
		// if (!self.volumeUniqueID) // for network volumes
		//    self.volumeUniqueID = [[theVolume volumeURL] absoluteString];
		// 
		// similar issue with relativePath, filevault is different, not at /
		// self.relativePath = [NTFileDesc relativePath:self.folder];
		
		self.caseSensitive = [theVolume caseSensitive];
		
		// path used for comparison, set to lower case on case insensitive volumes
		self.comparePath = self.relativePath;
		if (!self.caseSensitive)
			self.comparePath = [self.comparePath lowercaseString];
	}
}	

- (NSString*)description;
{
	return [NSString stringWithFormat:@"%@(%@) vol:%@", [self.folder path], self.comparePath, self.volumeUniqueID];
}

@end

