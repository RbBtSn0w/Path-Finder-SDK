//
//  NTOpenWithUIModelThread.m
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 2/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTOpenWithUIModelThread.h"
#import "NTOpenWithUIModel.h"
#import "NTPluginConstants.h"

@interface NTOpenWithUIModelThread ()
@property (nonatomic, retain) NSArray *descs;
@end

@interface NTOpenWithUIModelThread (hidden)
- (void)setModel:(NTOpenWithUIModel *)theModel;
@end

@implementation NTOpenWithUIModelThread

@synthesize descs;

+ (NTThreadRunner*)thread:(NSArray*)descs
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;
{
    NTOpenWithUIModelThread* param = [[[NTOpenWithUIModelThread alloc] init] autorelease];
    
    [param setDescs:descs];
	
	return [NTThreadRunner thread:param
						 priority:.8
						 delegate:delegate];	
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{	
    [self setDescs:nil];
    [self setModel:nil];
    [super dealloc];
}

//---------------------------------------------------------- 
//  model 
//---------------------------------------------------------- 
- (NTOpenWithUIModel *)model
{
	if (!mModel)
		[self setModel:[NTOpenWithUIModel model]];
	
    return mModel; 
}

- (void)setModel:(NTOpenWithUIModel *)theModel
{
    if (mModel != theModel)
    {
        [mModel release];
        mModel = [theModel retain];
    }
}

@end

@implementation NTOpenWithUIModelThread (Thread)

- (BOOL)applicationsMatch:(NTFileDesc**)outApp;
{
	NSEnumerator* enumerator = [[self descs] objectEnumerator];
	NTFileDesc* desc;
	NTFileDesc* appDesc=nil;
	BOOL firstTime=YES;
	NTFileDesc* lastAppDesc=nil;
	
	while (desc = [enumerator nextObject])
	{
		appDesc = [desc application];
		if (![appDesc isValid])
			appDesc = nil;

		if (!firstTime)
		{			
			if (lastAppDesc && appDesc)
			{
				if (![appDesc isEqualToDesc:lastAppDesc])
					return NO;
			}
			else if (lastAppDesc != appDesc)  // both nil?  that's OK. If (nil == nil)
				return NO;
		}
		
		lastAppDesc = appDesc;
		firstTime = NO;
	}
	
	if (outApp)
		*outApp = appDesc;
	
	return YES;
}

// override from the base class
- (BOOL)doThreadProc;
{
	NTOpenWithUIModel* model = [NTOpenWithUIModel model];		
	
	if ([[self descs] count])
	{
		NTFileDesc* currentApp=nil;

		if ([self applicationsMatch:&currentApp])
		{
			NTFileDesc* desc = [[self descs] objectAtIndex:0];
			NSArray* appDescs = [NTLaunchServices applicationURLsForItem:desc];
			
			NSMutableArray* appItems = [NSMutableArray array];
			NTFileDesc* appDesc;
			
			for (appDesc in appDescs)
				[appItems addObject:[NTOpenWithUIModelItem item:appDesc]];
			
			NTOpenWithUIModelItem* currentAppItem = nil;
			if (currentApp)
			{
				currentAppItem = [NTOpenWithUIModelItem item:currentApp];

				if (![appItems containsObject:currentAppItem])
					[appItems addObject:currentAppItem];
			}
			
			// sort by desc
			[appItems sortUsingSelector:@selector(compareByName:)];
			
			if (currentAppItem)
				[model setSelectedItem:currentAppItem];
			
			if (![appItems count])
			{
				NTOpenWithUIModelItem* noneItem = [NTOpenWithUIModelItem itemWithCommand:0 title:[NTLocalizedString localize:@"None" table:@"menuBar"]];
				[appItems addObject:noneItem];
				
				[model setSelectedItem:noneItem];
			}
			
			// now add the "Other..." choice
			[appItems addObject:[NTOpenWithUIModelItem separator]];
			[appItems addObject:[NTOpenWithUIModelItem itemWithCommand:kChoosePopupCommand title:[NTLocalizedString localize:@"Choose..." table:@"Get Info"]]];
			
			// should we enable the change all button?
			if (([desc isFile] || [desc isPackage]) && ![desc isApplication])
			{
				FSRef outAppRef;
				
				// if this file has a strong binding, then enable the menu
				OSStatus err = [NTLaunchServiceHacks LSGetStrongBindingForRef:[desc FSRefPtr] outAppRef:&outAppRef];
				
				if (err == noErr)
					[model setChangeAllEnabled:YES];
			}
			
			// set our result
			[model setItems:appItems];
			[model setDescs:[self descs]];
			[self setModel:model];
		}
	}
	
	return ![[self helper] killed];	
}
	
@end
