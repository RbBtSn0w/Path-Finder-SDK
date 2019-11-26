//
//  NTVolumeNotificationMgr.m

#import "NTVolumeNotificationMgr.h"
#import "NTVolume.h"
#import "NTFSWatcher.h"
#import "NTVolumeSpec.h"
#import "NTVolumeMgrState.h"

@interface NTVolumeNotificationMgr (Private)
- (void)sendNotifications;

- (NTFSWatcher *)fsWatcher;
- (void)setFSWatcher:(NTFSWatcher *)theFSWatcher;
@end

@interface NTVolumeNotificationMgr (Protocols) <NTFSWatcherDelegateProtocol>
@end

@implementation NTVolumeNotificationMgr

NTSINGLETONOBJECT_STORAGE;
NTSINGLETON_INITIALIZE;

@synthesize sendingDelayedNotifications, notificationDictionary;

- (id)init;
{
    self = [super init];
        	    
    // must be notified when the filesystem changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(volumeMountedNotification:)
                                                               name:NSWorkspaceDidMountNotification
                                                             object:nil];
    
    // must be notified when the filesystem changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(volumeMountedNotification:)
                                                               name:NSWorkspaceDidUnmountNotification
                                                             object:nil];
        	
	[self setFSWatcher:[NTFSWatcher watcher:self]];
	[[self fsWatcher] watchItem:[NTFileDesc descNoResolve:@"/Volumes"]];
	
    return self;
}

- (void)dealloc;
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self setFSWatcher:nil];
	self.notificationDictionary = nil;
	
    [super dealloc];
}

- (void)manuallyRefresh;
{
	[self sendNotifications];
}

// utility function for kNTVolumeMgrVolumeHasMountedNotification
// works around 10.6 bug
+ (NTFileDesc*)extractMountPointFromDictionary:(NSDictionary*)theDictionary;
{
	NTFileDesc* result = nil;
	
	// if we mounted a disk, make sure it's one we care about, don't check this for unmount since the disk is already gone
	// and will fail if we check it by the mount point
	NSString* mountPoint = [theDictionary objectForKey:@"NSDevicePath"];
	
	if (mountPoint)
	{
		result = [NTFileDesc descNoResolve:mountPoint];
		
		// 10.6 has a new behavior, for network volumes getting /shareName rather than /Volumes/shareName
		// if not a valid path, add the /Volumes on there
		if (![result isValid])
		{
			NSString* fixedMountPoint = @"/";
			fixedMountPoint = [fixedMountPoint stringByAppendingPathComponent:@"Volumes"];
			fixedMountPoint = [fixedMountPoint stringByAppendingPathComponent:[mountPoint lastPathComponent]];
			
			result = [NTFileDesc descNoResolve:fixedMountPoint];
			if (![result isValid])
				result = nil;
		}
	}
	
	return result;
}

@end

@implementation NTVolumeNotificationMgr (Protocols)

// NTFSWatcherDelegateProtocol
- (void)watcher:(NTFSWatcher*)watcher itemsChanged:(NSArray*)descs;
{
	[self sendNotifications];
}

@end

// ==================================================================

@implementation NTVolumeNotificationMgr (Private)

- (void)sendNotifications;
{
    if (!self.sendingDelayedNotifications)
    {
        self.sendingDelayedNotifications = YES;
        
        [self performDelayedSelector:@selector(sendNotificationsAfterDelay:) withObject:nil delay:.1];
    }
}

- (void)sendNotificationsAfterDelay:(id)unused;
{
	[NTVolumeMgrState incrementBuild];
	
    // notify any one registered
    [[NSNotificationCenter defaultCenter] postNotificationName:kNTVolumeMgrVolumeListHasChangedNotification object:self];
    
    if (self.notificationDictionary)
    {
        // send out notification to the rest of the app
        [[NSNotificationCenter defaultCenter] postNotificationName:kNTVolumeMgrVolumeHasMountedNotification object:self userInfo:self.notificationDictionary];
		
        self.notificationDictionary = nil;
    }
	
	self.sendingDelayedNotifications = NO;
}

// not reliable for network volumes, we don't always get the notification
- (void)volumeMountedNotification:(NSNotification*)notification;
{
    BOOL sendNotifiction = NO;
    
    // create a new mount dict and add it to the array
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
    
    // is this a mount or unmount
    if ([[notification name] isEqualToString:NSWorkspaceDidUnmountNotification])
    {
        [dict setObject:kUnMountEvent forKey:kMountEventKey];
        
        sendNotifiction = YES;
    }
    else
    {
        [dict setObject:kMountEvent forKey:kMountEventKey];
        
        // if we mounted a disk, make sure it's one we care about, don't check this for unmount since the disk is already gone
        // and will fail if we check it by the mount point
		NTFileDesc* mountPoint = [NTVolumeNotificationMgr extractMountPointFromDictionary:[notification userInfo]];
				
        if (mountPoint && [[NTVolumeSpec volumeWithMountPoint:mountPoint] isUserVolume])
            sendNotifiction = YES;
    }
    
    // make sure this isn't a volume we are going to filter out anyway
    if (sendNotifiction)
    {
        if (!self.notificationDictionary)
            self.notificationDictionary = [NSMutableDictionary dictionary];
        
        NSMutableArray *arrayOfNotifications = [self.notificationDictionary objectForKey:kMountEventArrayKey];
        if (!arrayOfNotifications)
        {
            arrayOfNotifications = [NSMutableArray array];
            [self.notificationDictionary setObject:arrayOfNotifications forKey:kMountEventArrayKey];
        }
                
        [arrayOfNotifications addObject:dict];
        
        [self sendNotifications];
    }
}

//---------------------------------------------------------- 
//  fsWatcher 
//---------------------------------------------------------- 
- (NTFSWatcher *)fsWatcher
{
    return mv_fsWatcher; 
}

- (void)setFSWatcher:(NTFSWatcher *)theFSWatcher
{
    if (mv_fsWatcher != theFSWatcher) {
		[mv_fsWatcher clearDelegate];
		
        [mv_fsWatcher release];
        mv_fsWatcher = [theFSWatcher retain];
    }
}

@end

// ====================================================================
