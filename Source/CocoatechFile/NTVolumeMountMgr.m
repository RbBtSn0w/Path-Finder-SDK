//
//  NTVolumeMountMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 12/16/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTVolumeMountMgr.h"
#import "NTVolumeMount.h"

@interface NTVolumeMountMgr ()
@property (nonatomic, retain) NSMutableDictionary *volumeURLDictionary;
@property (nonatomic, retain) NSMutableDictionary *activeVolumeMounters;
@end

@implementation NTVolumeMountMgr

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

@synthesize volumeURLDictionary;
@synthesize activeVolumeMounters;

- (id)init;
{
	self = [super init];
	
	self.activeVolumeMounters = [NSMutableDictionary dictionary];
	self.volumeURLDictionary = [NSMutableDictionary dictionary];

	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.volumeURLDictionary = nil;
    self.activeVolumeMounters = nil;
    [super dealloc];
}

- (void)mountVolumeWithURL:(NSURL*)url user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)notificationName;
{
	NSString* theKey = [NTVolumeMount dictionaryKey:url userName:user];
	
	if (![self.activeVolumeMounters objectForKey:theKey])
	{
		NTVolumeMount* result = [NTVolumeMount mountVolumeWithURL:url user:user password:password notifyWhenMounts:notificationName dictionaryKey:theKey];
	
		if (result)
			[self.activeVolumeMounters setObject:result forKey:theKey];
	}
}

- (void)mountVolumeWithScheme:(NSString*)scheme host:(NSString*)host path:(NSString*)path user:(NSString*)user password:(NSString*)password notifyWhenMounts:(NSString*)notificationName;
{
    NSString* urlString;
	
    if (path && [path length])
        urlString = [NSString stringWithFormat:@"%@://%@/%@", scheme, host, path];
    else
        urlString = [NSString stringWithFormat:@"%@://%@", scheme, host];
	
    @try {
        [self mountVolumeWithURL:[[[NSURL alloc] initWithString:urlString] autorelease] user:user password:password notifyWhenMounts:notificationName];
	}
	@catch (NSException * e) {
	}
	@finally {
	}
}

@end

@implementation NTVolumeMountMgr (UsedInternally)

- (void)volumeMountCompleted:(NTVolumeMount*)theMount;
{
	// this releases the NTVolumeMount which will allow it to dealloc
	[self.activeVolumeMounters removeObjectForKey:[theMount dictionaryKey]];
}

- (NTFileDesc*)volumeForURL:(NSURL*)theUrl;
{
    NTFileDesc* result = nil;
    
    if (self.volumeURLDictionary)
    {
        NSString* path = [self.volumeURLDictionary objectForKey:theUrl];
		
        if (path)
        {
            result = [NTFileDesc descNoResolve:path];
			
            if (![result isValid])
                result = nil;   // it's autoreleased, so nil is fine
        }
    }
	
    return result;
}

- (void)setVolume:(NTFileDesc*)volumeDesc forURL:(NSURL*)theURL;
{	
    [self.volumeURLDictionary setObject:[volumeDesc path] forKey:theURL];
}

@end
