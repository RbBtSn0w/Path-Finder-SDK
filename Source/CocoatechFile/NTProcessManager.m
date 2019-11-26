#import "NTProcessManager.h"
#import "NTLaunchServices.h"

@interface NTProcessManager (Private)
- (void)updateProcesses:(NSNotification*)notification;
- (NSArray*)processArrayToDescArray:(NSArray*)processes;
@end

@interface NTProcessManager (hidden)
- (void)setProcesses:(NSArray *)theProcesses;
@end

@implementation NTProcessManager

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init
{
    self = [super init];
	
    [self performDelayedSelector:@selector(updateProcesses:) withObject:nil];  // delay to improve launch time
		
	 // NSWorkspace notifications don't include background applications
	 [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															selector:@selector(updateProcesses:)
																name:NSWorkspaceDidLaunchApplicationNotification
															  object:nil];
	 
	 [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															selector:@selector(updateProcesses:)
																name:NSWorkspaceDidTerminateApplicationNotification
															  object:nil];
	
	 return self;
}

- (void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];	

    [_currentProcess release];
    [self setProcesses:nil];

    [super dealloc];
}

- (NTProcess*)currentProcess
{
    if (!_currentProcess)
    {
        ProcessSerialNumber psn;
        
        OSErr err = MacGetCurrentProcess(&psn);
        
        if (!err)
            _currentProcess = [[NTProcess processWithPSN:psn] retain];
    }
    
    return _currentProcess;
}

- (NTProcess*)frontProcess
{
    ProcessSerialNumber psn;
    OSErr err = GetFrontProcess(&psn);

    if (!err)
        return [NTProcess processWithPSN:psn];
    
    return nil;
}

- (void)hideAllExcept:(NTProcess*)dontHideProcess;
{
    // make sure the one we are excluding is shown, there must be at least one shown application
    [dontHideProcess show];
    
	NSArray *p = [[self processes] retain];

    for (NTProcess *process in p)
    {
        if(![process isEqual:dontHideProcess])
            [process hide];
    }

    [p release];
}

// name is not unique and localized
- (NTProcess*)processWithLocalizedName:(NSString*)name;
{
    NSArray* procs = [self processes];
	
    for (NTProcess* process in procs)
    {
        if ([[process displayName] isEqualToString:name])
            return process;
    }
	
    return nil;
}

- (NTProcess*)processWithName:(NSString*)name;
{
    NSArray* procs = [self processes];
	
    for (NTProcess* process in procs)
    {
        if ([[process name] isEqualToString:name])
            return process;
    }
	
    return nil;
}

// name is not unique, path is
- (NTProcess*)processWithPath:(NSString*)path;
{
    NSArray* procs = [self processes];

    for (NTProcess* process in procs)
    {
        if ([[[process desc] path] isEqualToString:path])
            return process;
    }

    return nil;
}

- (NSArray*)foregroundProcesses;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[[self processes] count]];
    
    for (NTProcess* process in [self processes])
    {
        if (![process isBackgroundOnly] && ![process isBackgroundOnlyWithUI])
            [result addObject:process];
    }
    
    return result;
}

- (NSArray*)backgroundOnlyProcesses;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[[self processes] count]];
    
    for (NTProcess* process in [self processes])
    {
        if ([process isBackgroundOnly] || [process isBackgroundOnlyWithUI])
            [result addObject:process];
    }
    
    return result;
}

- (NSArray*)foregroundProcessDescs;
{
    return [self processArrayToDescArray:[self foregroundProcesses]];
}

- (NSArray*)processDescs;
{
    return [self processArrayToDescArray:[self processes]];
}

- (NSArray*)backgroundOnlyProcessDescs;
{
    return [self processArrayToDescArray:[self backgroundOnlyProcesses]];
}

+ (void)restartSystemUIServer;
{
	system("ps -axcopid,command | grep \"SystemUIServer\" | awk '{ system(\"kill -9 \"$1) }'");
}

//---------------------------------------------------------- 
//  processes 
//---------------------------------------------------------- 
- (NSArray *)processes
{
	NSArray* result;
	
	@synchronized(self) {
		result = [[mProcesses retain] autorelease];
	}
	
    return result; 
}

- (void)setProcesses:(NSArray *)theProcesses
{
	@synchronized(self) {
		if (mProcesses != theProcesses)
		{
			[mProcesses release];
			mProcesses = [theProcesses retain];
		}
	}
}

@end

@implementation NTProcessManager (Private)

// returns an array of FileDescs, one for every running application
- (NSArray*)processArrayToDescArray:(NSArray*)processes;
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[processes count]];
    NTFileDesc* desc;
    
    for (NTProcess* process in processes)
    {
        desc = [process desc];
        
        if ([desc isValid])
            [result addObject:desc];
    }
    
    return result;
}

- (void)updateProcesses:(NSNotification*)notification;
{
    ProcessSerialNumber psn = {kNoProcess, kNoProcess};
    OSErr err;
    
    NSMutableArray *newProcesses = [NSMutableArray array];

    for (;;)
    {
        err = GetNextProcess(&psn);
        
        if (err)
            break;
        
        NTProcess* process = [NTProcess processWithPSN:psn];
                
		if (process)
			[newProcesses addObject:process];
    }
    
	[self setProcesses:newProcesses];
	
    // notify anyone would needs to know when we changed
	[[NSNotificationCenter defaultCenter] postNotificationName:kNTProcessManagerNotification object:self];
}

@end
