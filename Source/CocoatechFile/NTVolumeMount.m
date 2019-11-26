//
//  NTVolumeMount.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Sep 03 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTVolumeMount.h"
#import "NTVolumeMountMgr.h"

@interface NTVolumeMount ()
@property (nonatomic, assign) FSVolumeOperation volumeOp;
@property (nonatomic, assign) FSVolumeMountUPP mountUPP;
@end

@interface NTVolumeMount (Private)
- (void)doMountVolumeWithURL:(NSURL*)theURL user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)theNotificationName;
@end

@implementation NTVolumeMount

@synthesize url;
@synthesize notificationName, dictionaryKey;
@synthesize volumeOp, mountUPP;

+ (NTVolumeMount*)mountVolumeWithURL:(NSURL*)url
								  user:(NSString*)user 
							  password:(NSString*)password
					  notifyWhenMounts:(NSString*)notificationName
					   dictionaryKey:(NSString*)theDictionaryKey;
{
	NTVolumeMount* result = [[NTVolumeMount alloc] init];
	
	result.dictionaryKey = theDictionaryKey;
	[result doMountVolumeWithURL:url user:user password:password notifyWhenMounts:notificationName];
	
	return [result autorelease];
}

+ (NSString*)dictionaryKey:(NSURL*)theURL userName:(NSString*)theUserName;
{
	return [NSString stringWithFormat:@"%@:%@", theURL, theUserName];
}

- (id)init;
{
    self = [super init];
    
	FSVolumeOperation theVolumeOp;
    OSStatus status = FSCreateVolumeOperation(&theVolumeOp);

	if (status == noErr)
		self.volumeOp = theVolumeOp;

    return self;
}

- (void)dealloc;
{
    self.volumeOp = nil;
    self.mountUPP = nil;
	self.dictionaryKey = nil;
    self.url = nil;
    self.notificationName = nil;
    
    [super dealloc];
}
    
// override
- (void)setVolumeOp:(FSVolumeOperation)theVolumeOp;
{
	if (theVolumeOp != volumeOp)
	{
		if (volumeOp)
			FSDisposeVolumeOperation(volumeOp);
		
		volumeOp = theVolumeOp;
	}	
}

// override
- (void)setMountUPP:(FSVolumeMountUPP)theMountUPP;
{
	if (theMountUPP != mountUPP)
	{
		if (mountUPP)
			DisposeFSVolumeMountUPP(mountUPP);
		
		mountUPP = theMountUPP;
	}
}

@end

@implementation NTVolumeMount (Private)

// called on main thread
void volumeMountCallback(FSVolumeOperation volumeOp, void *clientData, OSStatus err, FSVolumeRefNum mountedVolumeRefNum)
{
	if (![NSThread isMainThread])
		NSLog(@"volumeMountCallback: not main thread");
	
    NTVolumeMount* mounter = (NTVolumeMount*)clientData;
    NTFileDesc *volumeDesc=nil;
    
    if (err != noErr)
    {
        // this error comes up when the volume is already mounted
        if (err == volOnLinErr)
        {
            volumeDesc = [[NTVolumeMountMgr sharedInstance] volumeForURL:[mounter url]];

            if (volumeDesc && [volumeDesc isValid])
            {
                if ([[mounter notificationName] length])
                    [[NSNotificationCenter defaultCenter] postNotificationName:[mounter notificationName] object:volumeDesc userInfo:nil];
            }
        }
        else if (err == userCanceledErr)
			; // user canceled, don't warn user
		else
        {
            NSString *messageString = [NTLocalizedString localize:@"An error occurred while trying to mount \"%@\"."];
            NSString *errorString = [NTLocalizedString localize:@"Error: %d"];

            messageString = [NSString stringWithFormat:messageString, [mounter url]];
            errorString = [NSString stringWithFormat:errorString, err];

			// got a crash here, when the panel runs it's event loop, it calls some callback and randomly hangs
			// delay message for main event loop just to be safe
			// NSArray *messages = [NSArray arrayWithObjects:messageString, errorString, nil];
			// [mounter performSelectorOnMainThread:@selector(displayErrorAfterDelay:) withObject:messages];
			
			NSLog(@"%@, err: %@", messageString, errorString);
        }
    }
    else if ([[mounter notificationName] length] && mountedVolumeRefNum != 0)
    {
        volumeDesc = [NTFileDesc descVolumeRefNum:mountedVolumeRefNum];

        if (volumeDesc && [volumeDesc isValid])
        {
            [[NTVolumeMountMgr sharedInstance] setVolume:volumeDesc forURL:[mounter url]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:[mounter notificationName] object:volumeDesc userInfo:nil];
        }
    }
    
	// this releases it
	[[NTVolumeMountMgr sharedInstance] volumeMountCompleted:mounter];
}

- (void)displayErrorAfterDelay:(id)object;
{
	NSString* messageString=@"";
	NSString* errorString=@"";
	
	if ([object isKindOfClass:[NSArray class]])
	{
		if ([object count])
			messageString = [object objectAtIndex:0];
		
		if ([object count] > 1)
			errorString = [object objectAtIndex:1];
	}
	
	[NTSimpleAlert alertPanel:messageString subMessage:errorString];
}

- (void)doMountVolumeWithURL:(NSURL*)theURL user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)theNotificationName;
{
    OSStatus err;
    CFStringRef userRef=nil, passRef=nil;
	
    self.url = theURL;
    self.notificationName = theNotificationName;
	
    // if no user name given, user the login name
    if (!user || ![user length])
        user = NSUserName();
	
    if (![self.url user])
    {
		if (user && [user length])
			userRef = (CFStringRef)user;
    }

    if (![self.url password])
    {
		// don't pass in nil for password, otherwise the name passed in doesn't get used ("public" for public iDisk for example)
        if (password)
            passRef = (CFStringRef)password;
    }
	
	// was getting a kernel panic and some strange stuff here
	// I'm assuming it might have something to do with the strings being autoreleased, so I added this retain and release around this call
	if (passRef)
		CFRetain(passRef);
	if (userRef)
		CFRetain(userRef);
	
	self.mountUPP = NewFSVolumeMountUPP(volumeMountCallback);
	err = FSMountServerVolumeAsync((CFURLRef)self.url, (CFURLRef)NULL, NULL, NULL, self.volumeOp, self, 0, self.mountUPP, CFRunLoopGetMain(), kCFRunLoopCommonModes);
	
	if (err)
		NSLogErr(@"FSMountServerVolumeAsync", err);
		
	if (passRef)
		CFRelease(passRef);
	if (userRef)
		CFRelease(userRef);	
}

@end
