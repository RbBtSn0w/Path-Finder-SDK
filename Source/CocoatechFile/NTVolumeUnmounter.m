//
//  NTVolumeUnmounter.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/4/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import "NTVolumeUnmounter.h"
#import "NTPartitionInfo.h"
#import "NTVolume.h"

static void volumeEjectCallback(FSVolumeOperation volumeOp, void *clientData, OSStatus err, FSVolumeRefNum volumeRefNum, pid_t dissenter);
static void volumeUnmountCallback(FSVolumeOperation volumeOp, void *clientData, OSStatus err, FSVolumeRefNum volumeRefNum, pid_t dissenter);

@interface NTVolumeUnmounter ()
@property (assign) FSVolumeOperation volumeOp;
@property (assign) FSVolumeEjectUPP ejectUPP;
@property (assign) FSVolumeUnmountUPP unmountUPP;
@property (retain) NTFileDesc *desc;
@end

@interface NTVolumeUnmounter (Private)
- (void)doUnmountVolumeThreadProc;
- (void)doEjectVolumeThreadProc;
+ (void)ejectVolumeWithModifiers:(NTFileDesc*)theDesc siblingsToUnmount:(NSArray*)inSiblingsToUnmount;
@end

@implementation NTVolumeUnmounter

@synthesize volumeOp;
@synthesize ejectUPP;
@synthesize unmountUPP;
@synthesize desc;

- (id)init;
{
    self = [super init];
    
	FSVolumeOperation op;
	OSStatus err = FSCreateVolumeOperation(&op);
	
	if (err == noErr)
		self.volumeOp = op;
	
    return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc;
{	
	if (self.volumeOp)
	{
		FSDisposeVolumeOperation(self.volumeOp);
		self.volumeOp = nil;
	}
	
    if (self.unmountUPP)
	{
		DisposeFSVolumeUnmountUPP(self.unmountUPP);
		self.unmountUPP = nil;
	}
	
    if (self.ejectUPP)
	{
        DisposeFSVolumeEjectUPP(self.ejectUPP);
		self.ejectUPP = nil;
	}
	
    self.desc = nil;
    
    [super dealloc];
}

// this was added to handle a list of volumes, for example a drag to trash, or CM click
+ (void)ejectVolumesWithModifiers:(NSArray*)theDescs;
{
	NSMutableArray* filteredDescs = nil;
	BOOL controlKeyDown = [NSEvent controlKeyDownNow];
	NSMutableDictionary* siblingDescsDict = nil;
	
	// case one: contolKeyDown - user wants to unmount just a partition, don't filter
	if (!controlKeyDown)
	{		
		// case two: optionKeyDown - user wants to eject all, just do one sibling to avoid errors
		// case three: last case is same as optionKeyDown, get rid of siblings
		NSArray* siblings;	
		NSMutableDictionary* bsdNameToDescMap = [NSMutableDictionary dictionary];
		for (NTFileDesc* theDesc in theDescs)
			[bsdNameToDescMap setObjectIf:theDesc forKey:[[theDesc volume] diskIDString]];
		
		NSMutableDictionary* siblingArrays = [NSMutableDictionary dictionary];
		siblingDescsDict = [NSMutableDictionary dictionary];
		for (NTFileDesc* theDesc in theDescs)
		{
			// siblings is a list of bsdnames
			siblings = [NTPartitionInfo siblingEjectablePartitionsForVolume:[theDesc volume]];
			
			if ([siblings count])
			{
				// siblings array
				[siblingArrays setObjectIf:siblings forKey:[theDesc dictionaryKey]];
				
				// convert to descs and store in siblingDescsDict
				NSMutableArray* siblingDescs = [NSMutableArray array];
				for (NSString* bsdName in siblings)
					[siblingDescs addObjectIf:[bsdNameToDescMap objectForKey:bsdName]];
				[siblingDescsDict setObjectIf:siblingDescs forKey:[theDesc dictionaryKey]];
			}
		}
		
		if ([siblingArrays count])
		{			
			filteredDescs = [NSMutableArray array];
			NSMutableArray *bsdNamesCovered = [NSMutableArray array];
			
			for (NTFileDesc* theDesc in theDescs)
			{
				BOOL add = YES;
				
				// only check for the second item, first one is always added
				if ([filteredDescs count])
				{
					siblings = [siblingArrays objectForKey:[theDesc dictionaryKey]];
					if ([siblings count])
					{
						for (NSString* bsdName in bsdNamesCovered)
						{
							if ([siblings containsObject:bsdName])
							{
								add = NO;
								break;
							}
						}
					}
				}
				
				if (add)
				{
					[filteredDescs addObject:theDesc];
					
					[bsdNamesCovered addObjectIf:[[theDesc volume] diskIDString]];
				}
			}
		}
	}
	
	if (!filteredDescs)
		filteredDescs = [NSMutableArray arrayWithArray:theDescs];
	
	for (NTFileDesc *theDesc in filteredDescs)
		[self ejectVolumeWithModifiers:theDesc siblingsToUnmount:[siblingDescsDict objectForKey:[theDesc dictionaryKey]]];
}

+ (void)ejectVolumeWithModifiers:(NTFileDesc*)theDesc;
{
	[self ejectVolumeWithModifiers:theDesc siblingsToUnmount:nil];
}

+ (void)unmountVolume:(NTFileDesc*)theDesc;
{	
	// calling unmount will unmount a volume, but not eject or park a firewire disk
    NTVolumeUnmounter* result = [[NTVolumeUnmounter alloc] init];
	LEAKOK(result);
	
	result.desc = theDesc;
    result.unmountUPP = NewFSVolumeUnmountUPP(volumeUnmountCallback);
	
    // this object autoreleases itself when done
    [NSThread detachNewThreadSelector:@selector(doUnmountVolumeThreadProc) toTarget:result withObject:nil];    
} 

+ (void)ejectVolume:(NTFileDesc*)theDesc;
{
    NTVolumeUnmounter* result = [[NTVolumeUnmounter alloc] init];
	LEAKOK(result);
	
	result.desc = theDesc;
	result.ejectUPP = NewFSVolumeEjectUPP(volumeEjectCallback);
	
    // this object autoreleases itself when done
	[NSThread detachNewThreadSelector:@selector(doEjectVolumeThreadProc) toTarget:result withObject:nil];    
}

+ (void)askEjectCallback:(NTAlertPanel*)alertPanel;
{
	NSDictionary* contextDictionary = (NSDictionary*)[alertPanel contextInfo];
	
	NTFileDesc* theDesc = [contextDictionary objectForKey:@"desc"];
	NSArray* theSiblings = [contextDictionary objectForKey:@"siblings"];
	
	switch ([alertPanel resultCode])
	{
		case NSAlertFirstButtonReturn:
			[self unmountVolume:theDesc];
			
			for (NTFileDesc* siblingDesc in theSiblings)
				[self unmountVolume:siblingDesc];
			break;
		case NSAlertSecondButtonReturn:
			[self ejectVolume:theDesc];
			break;
		case NSAlertThirdButtonReturn:
			// cancel
		default:
			break;
	}
}

@end

@implementation NTVolumeUnmounter (Private)

+ (void)ejectVolumeWithModifiers:(NTFileDesc*)theDesc siblingsToUnmount:(NSArray*)inSiblingsToUnmount
{
	BOOL controlKeyDown = [NSEvent controlKeyDownNow];
	
	if (controlKeyDown)
		[self unmountVolume:theDesc];
	else
	{
		NTVolume* theVolume = [theDesc volume];
		NSArray* siblings = nil;
		BOOL optionKeyDown = [NSEvent optionKeyDownNow];
		
		if (!optionKeyDown)
			siblings = [NTPartitionInfo siblingEjectablePartitionsForVolume:theVolume];
		
		if ([siblings count])
		{
			NSMutableDictionary* contextDictionary = [NSMutableDictionary dictionary];
			[contextDictionary setObjectIf:theDesc forKey:@"desc"];
			[contextDictionary setObjectIf:inSiblingsToUnmount forKey:@"siblings"];
			
			NSString* titleFormat = [NTLocalizedString localize:@"The device containing \"%@\" also contains %d other volumes that will not be ejected. Are you sure you want to eject \"%@\"?"];
			
			if ([siblings count] == 1)
				titleFormat = [NTLocalizedString localize:@"The device containing \"%@\" also contains %d other volume that will not be ejected. Are you sure you want to eject \"%@\"?"];
			
			NSString* title = [NSString stringWithFormat:titleFormat, [[theVolume mountPoint] displayName], [siblings count], [[theVolume mountPoint] displayName]];
			
			NSString* message = [NTLocalizedString localize:@"To eject all the volumes on this device, click Eject All, or hold down the Option key while ejecting the volume."
								 "\n\nIn the future, to eject a single volume without seeing this dialog, hold down the Control key while ejecting the volume."];
			
			[NTAlertPanel show:NSCriticalAlertStyle
						target:self 
					  selector:@selector(askEjectCallback:)
						 title:title
					   message:message
					   context:contextDictionary 
						window:nil
			defaultButtonTitle:[NTLocalizedString localize:@"Eject"]
		  alternateButtonTitle:[NTLocalizedString localize:@"Eject All"]
			  otherButtonTitle:[NTLocalizedString localize:@"Cancel"]
		  enableEscOnAlternate:NO
			  enableEscOnOther:YES
				   defaultsKey:nil];
		}
		else
			[self ejectVolume:theDesc];
	}
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

- (void)doUnmountVolumeThreadProc;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    OSStatus err = FSUnmountVolumeAsync([self.desc volumeRefNum], 0, self.volumeOp, self, self.unmountUPP, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	
	if (err)
		NSLog(@"FSUnmountVolumeAsync err:%d", err);
	
	[pool release];
	pool = nil;
}

- (void)doEjectVolumeThreadProc;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    OSStatus err = FSEjectVolumeAsync([self.desc volumeRefNum], 0, self.volumeOp, self, self.ejectUPP, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	
	if (err)
		NSLog(@"FSEjectVolumeAsync err:%d", err);
	
	[pool release];
	pool = nil;
}

@end

static void volumeUnmountCallback(FSVolumeOperation volumeOp, void *clientData, OSStatus err, FSVolumeRefNum volumeRefNum, pid_t dissenter)
{
	// does this need a pool?  maybe
	NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	{
		NTVolumeUnmounter* theSelf = (NTVolumeUnmounter*)clientData;
		
		if (err != noErr)
		{
			NTFileDesc* volumeDesc = [theSelf desc];
			NSString *messageString = [NTMacErrorString macErrorString:err];
			NSString *errorString = [NTLocalizedString localize:@"Error: %d"];
			
			if (!messageString)
			{
				messageString = [NTLocalizedString localize:@"An error occurred while trying to unmount \"%@\"."];
				messageString = [NSString stringWithFormat:messageString, [volumeDesc displayName]];
			}
			
			errorString = [NSString stringWithFormat:errorString, err];
			
			// got a crash here, when the panel runs it's event loop, it calls some callback and randomly hangs
			// delay message for main event loop just to be safe
			NSArray *messages = [NSArray arrayWithObjects:messageString, errorString, nil];
			[theSelf performSelectorOnMainThread:@selector(displayErrorAfterDelay:) withObject:messages];
		}
		
		[theSelf autorelease];
	}
	[thePool release];
	thePool = nil;
}

static void volumeEjectCallback(FSVolumeOperation volumeOp, void *clientData, OSStatus err, FSVolumeRefNum volumeRefNum, pid_t dissenter)
{
	// does this need a pool?  maybe
	NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	{		
		NTVolumeUnmounter* theSelf = (NTVolumeUnmounter*)clientData;
		
		if (err != noErr)
		{
			NSString *messageString = [NTMacErrorString macErrorString:err];
			NSString *errorString = [NTLocalizedString localize:@"Error: %d"];
			
			if (!messageString)
			{
				NTFileDesc* volumeDesc = [theSelf desc];
				
				messageString = [NTLocalizedString localize:@"An error occurred while trying to eject \"%@\"."];
				messageString = [NSString stringWithFormat:messageString, [volumeDesc displayName]];
			}
			
			errorString = [NSString stringWithFormat:errorString, err];
			
			// got a crash here, when the panel runs it's event loop, it calls some callback and randomly hangs
			// delay message for main event loop just to be safe
			NSArray *messages = [NSArray arrayWithObjects:messageString, errorString, nil];
			[theSelf performSelectorOnMainThread:@selector(displayErrorAfterDelay:) withObject:messages];
		}
		
		[theSelf autorelease];
	}
	[thePool release];
	thePool = nil;	
}

