//
//  NSRunningApplication-NTExtensions.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 9/14/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NSRunningApplication-NTExtensions.h"
#import "NTRunningAppManager.h"
#import "NTLaunchServices.h"

@implementation NSRunningApplication (NTExtensionsNSCoding)

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
	NSLog(@"-[%@ %@] not supported", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
	NSLog(@"-[%@ %@] not supported", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return nil;
}

@end

@implementation NSRunningApplication (NTExtensions)

+ (NSRunningApplication*)activeApplication;
{
	for (NSRunningApplication* app in [NTRM applications])
	{
		if (app.isActive)
			return app;
	}
	
	return nil;
}

- (BOOL)isRegular;
{
	return (self.activationPolicy == NSApplicationActivationPolicyRegular);
}

- (BOOL)isBackgroundOnly;
{
	return (self.activationPolicy == NSApplicationActivationPolicyProhibited);
}

- (BOOL)isBackgroundOnlyWithUI;
{
	return (self.activationPolicy == NSApplicationActivationPolicyAccessory);
}

- (NSComparisonResult)compareByName:(NSRunningApplication*)theRight;
{
	return [self.localizedName compare:theRight.localizedName];
}

- (BOOL)activateAllWindows:(BOOL)allWindows unminimize:(BOOL)unminimize;
{
	NSApplicationActivationOptions options = NSApplicationActivateIgnoringOtherApps;
	
	if (allWindows)
		options |= NSApplicationActivateIgnoringOtherApps;
	
	BOOL result = [self activateWithOptions:options];
	
	// unminimizes any windows
	if (unminimize)
	{
		NTFileDesc* desc = [NTFileDesc descNoResolve:[[self bundleURL] path]];
		
		if ([desc isValid])
			[NTLaunchServices launchDescs:[NSArray arrayWithObject:desc] withApp:nil launchFlags:kLSLaunchDefaults];
	}
	
	return result;
}

- (NTFileDesc*)desc;
{
	if (self.bundleURL)
		return [NTFileDesc descNoResolve:[self.bundleURL path]];
	
	// maybe it's not a bundle?  Carbon app?
	return [NTFileDesc descNoResolve:[self.executableURL path]];
}

@end
