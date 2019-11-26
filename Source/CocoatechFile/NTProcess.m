#import "NTProcess.h"
#import "NTProcessManager.h"
#import "NTLaunchServices.h"

OSErr SendEvent(AEEventClass theAEEventClass, AEEventID theAEEventID, AEAddressDesc* theTargetAddressPtr);

@interface NTProcess (Private)
- (void)setIsValid:(BOOL)flag;

- (NSDictionary *)dictionary;
- (void)setDictionary:(NSDictionary *)theDictionary;

- (void)setDesc:(NTFileDesc *)theDesc;

- (void)setPsn:(ProcessSerialNumber)thePsn;

- (ProcessSerialNumber*)psnPtr;
@end

@implementation NTProcess


- (id)initWithPSN:(ProcessSerialNumber)psn;
{
    self = [super init];
	
    CFDictionaryRef dictRef = ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
    
    if (dictRef)
    {
        [self setIsValid:YES];
        
        [self setPsn:psn];
        [self setDictionary:(NSDictionary*)dictRef];
		
        CFRelease(dictRef);
    }
    
    return self;
}

+ (NTProcess*)processWithPSN:(ProcessSerialNumber)psn;
{
    NTProcess* result = [[self alloc] initWithPSN:psn];

    return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDictionary:nil];
    [self setDesc:nil];
    [super dealloc];
}

//---------------------------------------------------------- 
//  isValid 
//---------------------------------------------------------- 
- (BOOL)isValid
{
    return mIsValid;
}

//---------------------------------------------------------- 
//  psn 
//---------------------------------------------------------- 
- (ProcessSerialNumber)psn
{
    return mPsn;
}

- (BOOL)isBackgroundOnly;
{
    NSNumber *boolNumber = [[self dictionary] objectForKey:@"LSBackgroundOnly"];
    
    return [boolNumber boolValue];
}

- (BOOL)isBackgroundOnlyWithUI;
{
    NSNumber *boolNumber = [[self dictionary] objectForKey:@"LSUIElement"];
    
    return [boolNumber boolValue];
}

//---------------------------------------------------------- 
//  desc 
//---------------------------------------------------------- 
- (NTFileDesc *)desc
{
	if (!mDesc)
		[self setDesc:[NTFileDesc descNoResolve:[[self dictionary] objectForKey:@"BundlePath"]]];
	
	return mDesc; 
}
	
- (NSString*)displayName;
{
    return [[self dictionary] objectForKey:@"CFBundleName"];
}

- (NSString*)name;
{
    return [[self desc] name];
}

// UInt32
- (NSNumber*)processID
{
    NSNumber *number = [[self dictionary] objectForKey:@"pid"];
    
    return number;
}

- (NSString*)processCreatorCode;
{
    NSString *creatorCode = [[self dictionary] objectForKey:@"FileCreator"];
    
    return creatorCode;
}

- (NSUInteger)hash
{
    return [self psn].lowLongOfPSN;
}

- (BOOL)isEqual:(id)anObject
{
    if( anObject )
    {
        Boolean result;
        OSErr err = SameProcess([self psnPtr], [anObject psnPtr], &result);
        
        if (!err)
            return result;
    }

    return NO;
}

- (BOOL)isEqualToCurrent
{
    return [self isEqual:[NTPM currentProcess]];
}

- (BOOL)isEqualToFront
{
    return [self isEqual:[NTPM frontProcess]];
}

- (BOOL)isStillRunning
{
    pid_t outPID;
        
    OSStatus err = GetProcessPID([self psnPtr], &outPID);
    
    return (err == noErr);
}

- (void)show
{
    ShowHideProcess([self psnPtr], YES);
}

- (BOOL)isHidden;
{
	return !IsProcessVisible([self psnPtr]);
}

- (void)hide
{
    ShowHideProcess([self psnPtr], NO);
}

- (void)makeFront:(BOOL)frontWindowOnly unminimizeWindows:(BOOL)unminimizeWindows;
{
    OptionBits options = 0;
    
    if (frontWindowOnly)
        options |= kSetFrontProcessFrontWindowOnly;
    
    SetFrontProcessWithOptions([self psnPtr], options);
	
	// unminimizes any windows
	if (unminimizeWindows)
		[NTLaunchServices launchDescs:[NSArray arrayWithObject:[self desc]] withApp:nil launchFlags:kLSLaunchDefaults];
}

- (void)quit;
{
    AEAddressDesc theTargetAddress;
    OSErr  theErr;
    
    theErr = AECreateDesc(typeProcessSerialNumber, 
                          (Ptr)[self psnPtr], sizeof([self psn]),
                          &theTargetAddress);
    
	if (!theErr)
	{
		theErr = SendEvent(kCoreEventClass, kAEQuitApplication, &theTargetAddress);
	
		if (theErr)
			NSLog(@"SendEvent error: %d", theErr);
		
		AEDisposeDesc(&theTargetAddress);
	}
}

- (void)kill;
{
    KillProcess([self psnPtr]);
}

- (NSString*)description;
{
    return [[self displayName] stringByAppendingString:[[self desc] description]];
}

- (NSComparisonResult)compareByProcessName:(NTProcess *)fsi;
{
    return ([[self displayName] caseInsensitiveCompare:[fsi displayName]]);
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [aCoder encodeObject:[NSNumber numberWithUnsignedLong:[self psn].highLongOfPSN] forKey:@"psn_high"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedLong:[self psn].lowLongOfPSN] forKey:@"psn_low"];
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    NSNumber* high, *low;
    
    high = [aDecoder decodeObjectForKey:@"psn_high"];
    low = [aDecoder decodeObjectForKey:@"psn_low"];
    
    if (high && low)
    {
        ProcessSerialNumber psn;

        psn.highLongOfPSN = [high unsignedLongValue];
        psn.lowLongOfPSN = [high unsignedLongValue];
        
        return [self initWithPSN:psn];
    }
    
    return nil;
}

@end

@implementation NTProcess (Private)

- (void)setIsValid:(BOOL)flag
{
    mIsValid = flag;
}

//---------------------------------------------------------- 
//  dictionary 
//---------------------------------------------------------- 
- (NSDictionary *)dictionary
{
    return mDictionary; 
}

- (void)setDictionary:(NSDictionary *)theDictionary
{
    if (mDictionary != theDictionary) {
        [mDictionary release];
        mDictionary = [theDictionary retain];
    }
}

- (void)setDesc:(NTFileDesc *)theDesc
{
    if (mDesc != theDesc) {
        [mDesc release];
        mDesc = [theDesc retain];
    }
}

- (void)setPsn:(ProcessSerialNumber)thePsn
{
    mPsn = thePsn;
}

- (ProcessSerialNumber*)psnPtr;
{
    return &mPsn;
}

@end

OSErr SendEvent(AEEventClass theAEEventClass, AEEventID theAEEventID, AEAddressDesc* theTargetAddressPtr)
{
    OSErr theErr = 0;
    AppleEvent theAppleEvent, theAEReply;
    
    theErr = AECreateAppleEvent(theAEEventClass,theAEEventID,
                                theTargetAddressPtr,kAutoGenerateReturnID,
                                kAnyTransactionID,&theAppleEvent);
    
	if (!theErr)
	{
		// no direct parameters so this one is easy
		theErr = AESend(&theAppleEvent, &theAEReply, kAENoReply, 
						kAENormalPriority, kAEDefaultTimeout, nil, nil);
	
		if (theErr)
			NSLog(@"AESend error: %d", theErr);
		
		AEDisposeDesc(&theAppleEvent);
	}
	return theErr;
}
