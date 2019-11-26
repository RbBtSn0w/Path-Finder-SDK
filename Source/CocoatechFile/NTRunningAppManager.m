//
//  NTRunningAppManager.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 9/13/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTRunningAppManager.h"
#import "NSRunningApplication-NTExtensions.h"
#import "NTLaunchServices.h"

@interface NTRunningAppManager ()
@property (nonatomic, retain) NTKVObserverProxy *observerProxy;
@property (nonatomic, retain) NSMutableArray *relaunchArray;
@property (retain) NSArray *applications;  // thread safe
@property (nonatomic, assign) BOOL sentNotificationAfterDelay;
@end

@interface NTRunningAppManager (KVO)
- (void)addKVObserver;
- (void)removeKVObserver;
@end

@interface NTRunningAppManager (Private)
- (void)relaunchAfterNotification;
@end

@interface NTRunningAppManager (Protocols) <NTKVObserverProxyDelegateProtocol>
@end

@implementation NTRunningAppManager

@synthesize observerProxy, relaunchArray, applications, sentNotificationAfterDelay;

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];
	
	self.relaunchArray = [NSMutableArray array];
	self.applications = [[NSWorkspace sharedWorkspace] runningApplications];  // get initial value, updates in observer

	[self addKVObserver];
	
	return self;
}

- (void)dealloc;
{
	[self removeKVObserver];
	self.relaunchArray = nil;
	self.applications = nil;
	
	[super dealloc];
}

- (NSArray*)regularApplications;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[self.applications count]];
    
    for (NSRunningApplication* application in self.applications)
    {
        if ([application isRegular])
            [result addObject:application];
    }
    
    return result;
}

- (NSArray*)backgroundApplications;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[self.applications count]];
    
    for (NSRunningApplication* application in self.applications)
    {
        if ([application isBackgroundOnly] || [application isBackgroundOnlyWithUI])
            [result addObject:application];
    }
    
    return result;
}

- (NSRunningApplication*)applicationWithURL:(NSURL*)theURL;
{
	for (NSRunningApplication* application in self.applications)
    {
        if ([[application bundleURL] isEqual:theURL])
            return application;
    }	
	
	return nil;
}

- (NSArray*)applicationsToDescs:(NSArray*)theApplications;
{
	NSMutableArray* result = [NSMutableArray array];
	
	for (NSRunningApplication* app in theApplications)
	{
		NTFileDesc *desc = app.desc;
		
		if ([desc isValid])
			[result addObject:desc];
	}
	
	return result;
}

- (NSRunningApplication*)applicationWithBundleIdentifier:(NSString*)theBundleIdentifier;
{
	for (NSRunningApplication* application in self.applications)
    {
        if ([[application bundleIdentifier] isEqualToString:theBundleIdentifier])
            return application;
    }	
	
	return nil;
}

- (void)showAll;
{
	for (NSRunningApplication* app in [self regularApplications])
		[app unhide];
}

- (void)quitAll;
{
	NSRunningApplication* currentApp = [NSRunningApplication currentApplication];
	for (NSRunningApplication* app in [self regularApplications])
	{
		if(![app isEqual:currentApp])
			[app terminate];
	}
}

- (void)hideFront;
{
	[[NSRunningApplication activeApplication] hide];
}

- (void)hideOthers
{	
    [self hideAllExcept:[NSRunningApplication activeApplication]];
}

- (void)hideAllExcept:(NSRunningApplication*)dontHideProcess;
{
    // make sure the one we are excluding is shown, there must be at least one shown application
    [dontHideProcess unhide];

	for (NSRunningApplication* app in [self regularApplications])
	{
		if(![app isEqual:dontHideProcess])
            [app hide];
	}
}

- (void)relaunch:(NSRunningApplication*)theRunningApplication;
{
	[self.relaunchArray addObject:[NTFileDesc descNoResolve:[[theRunningApplication bundleURL] path]]];

	[theRunningApplication terminate];
}

@end

@implementation NTRunningAppManager (Private)

- (void)relaunchAfterNotification;
{	
	for (NTFileDesc *desc in self.relaunchArray)
		[NTLaunchServices launchDescs:nil withApp:[desc path] launchFlags:kLSLaunchDefaults | kLSLaunchDontSwitch];
	
	[self.relaunchArray removeAllObjects];
}

@end

@implementation NTRunningAppManager (KVO)

- (void)addKVObserver;
{
	self.observerProxy = [NTKVObserverProxy proxy:self];
	
	[[NSWorkspace sharedWorkspace] addObserver:self.observerProxy
									forKeyPath:@"runningApplications"
									   options:NSKeyValueObservingOptionOld
									   context:NULL];
}

- (void)removeKVObserver;
{
	[[NSWorkspace sharedWorkspace] removeObserver:self.observerProxy forKeyPath:@"runningApplications"];
	
	self.observerProxy.delegate = nil;
	self.observerProxy = nil;
}

@end

@implementation NTRunningAppManager (Protocols)

// NTKVObserverProxyDelegateProtocol

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if ([keyPath isEqualToString:@"runningApplications"])
	{
		if (!self.sentNotificationAfterDelay)
		{
			self.sentNotificationAfterDelay = YES;
			[self performDelayedSelector:@selector(notifyAfterDelay) withObject:nil delay:.25];
		}
	}
}

- (void)notifyAfterDelay;
{
	self.sentNotificationAfterDelay = NO;

	if (![NSThread isMainThread])
		NSLog(@"notifyAfterDelay not main thread");
	
	self.applications = [[NSWorkspace sharedWorkspace] runningApplications];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNTRunningAppManagerNotification object:self];
	
	[self relaunchAfterNotification];
}

@end

