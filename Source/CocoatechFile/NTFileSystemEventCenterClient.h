//
//  NTFileSystemEventCenterClient.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/29/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kNTComputerEventClient @"NTComputerEventClient"

@class NTFileSystemEventMessage;

@interface NTFileSystemEventCenterClient : NSObject {
	NSString* relativePath;
	NSString* comparePath;
	NTMessageProxy* delegateProxy;
	NSString *volumeUniqueID;
	BOOL caseSensitive;
	BOOL includeSubfolders;
	NTFileDesc* folder;
	NSNumber* uniqueID;
	BOOL isReadOnly;
	BOOL sentPendingMessage;
	NSMutableArray* pendingMessages;
}

@property (readonly, nonatomic, retain) NSString *relativePath;
@property (readonly, nonatomic, retain) NSString *comparePath;
@property (readonly, nonatomic, retain) NSString *volumeUniqueID;
@property (readonly, nonatomic, assign) BOOL caseSensitive;
@property (readonly, nonatomic, assign) BOOL includeSubfolders;
@property (readonly, nonatomic, assign) BOOL isReadOnly;
@property (readonly, nonatomic, retain) NTFileDesc* folder;
@property (readonly, nonatomic, retain) NSNumber* uniqueID;

+ (NTFileSystemEventCenterClient*)client:(NTMessageProxy*)theDelegateProxy 
								  folder:(NTFileDesc*)theFolder 
					   includeSubfolders:(BOOL)includeSubfolders 
								uniqueID:(NSNumber*)uniqueID;

@end

@interface NTFileSystemEventCenterClient (InternalAccessOnly)
- (void)initializeValues;
- (void)notify:(NTFileSystemEventMessage*)theMessage;
@end
