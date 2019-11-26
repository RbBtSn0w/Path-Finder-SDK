//
//  NTAuthOpen.m
//  CocoaTechFoundation
//
//  Created by Steve Gehrman on 3/29/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTAuthOpen.h"

@interface NTAuthOpen (Private)
- (void)disposeReadTask;
- (void)disposeWriteTask;
- (id)uniqueNotificationObject;
- (void)postNotification:(id)task;
- (void)doWriteData:(NSData*)input toFile:(NTFileDesc*)desc;
- (void)doReadDataFromFile:(NTFileDesc*)desc;
@end

#define kAuthOpenToolPath @"/usr/libexec/authopen"

@interface NTAuthOpen (Protocols) <NTTaskControllerDelegateProtocol>
@end

@implementation NTAuthOpen

@synthesize readData, notificationObject;

- (id)init;
{
	self = [super init];
		
	[self setNotificationObject:[self uniqueNotificationObject]];

	return self;
}

- (void)dealloc;
{		
	[self disposeWriteTask];
	[self disposeReadTask];
	[self setNotificationObject:[self uniqueNotificationObject]];
	[self setReadData:nil];
	
	[super dealloc];
}

+ (id)writeData:(NSData*)input toFile:(NTFileDesc*)desc;
{
	NTAuthOpen *authOpen = [[NTAuthOpen alloc] init];  // releases self when complete
	LEAKOK(authOpen);

	[authOpen doWriteData:input toFile:desc];
	
	return [authOpen notificationObject];
}

+ (id)readDataFromFile:(NTFileDesc*)desc;
{
	NTAuthOpen *authOpen = [[NTAuthOpen alloc] init];  // releases self when complete
	LEAKOK(authOpen);

	[authOpen doReadDataFromFile:desc];
	
	return [authOpen notificationObject];	
}

+ (void)observe:(id)target selector:(SEL)selector object:(id)object;
{
	if (object)
	{
		[[NSNotificationCenter defaultCenter] addObserver:target
												 selector:selector
													 name:NTAuthOpenCompletionNotification
												   object:object];	
	}
}

+ (void)remove:(id)target object:(id)object;
{
	if (object)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:target
														name:NTAuthOpenCompletionNotification
													  object:object];	
	}
}

@end

@implementation NTAuthOpen (Private)

- (void)doWriteData:(NSData*)input toFile:(NTFileDesc*)desc;
{
	// If -w is specified, authopen will read from stdin and write to the file.
	NSArray* args = [NSArray arrayWithObjects:@"-w", [desc path], nil];
	
	mv_writeTask = [[NTTaskController alloc] initWithTaskDelegate:self];
	[mv_writeTask runTask:kAuthOpenToolPath directory:nil withArgs:args input:input];
}

- (void)doReadDataFromFile:(NTFileDesc*)desc;
{
	NSArray* args = [NSArray arrayWithObjects:[desc path], nil];
	
	mv_readTask = [[NTTaskController alloc] initWithTaskDelegate:self];
	
	// get the file in one big read, otherwise big files are super slow with all the notifications
	[mv_readTask setReadTilEndOfFile:YES];
	[mv_readTask runTask:kAuthOpenToolPath directory:nil withArgs:args];
}

- (void)disposeReadTask;
{
	[mv_readTask clearDelegate];
	[mv_readTask release];
	mv_readTask = nil;
}

- (void)disposeWriteTask;
{
	[mv_writeTask clearDelegate];
	[mv_writeTask release];
	mv_writeTask = nil;
}

- (id)uniqueNotificationObject;
{
	static int shared=0;
	
	shared++;
	
	return [NSNumber numberWithUnsignedInt:shared];
}

- (void)postNotification:(id)task;
{
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	NSData* data = [self readData];
	
	if (data)
	{
		// check for an error, error is passed to stdout - stupid
		// "AuthorizationCreate failed with -60006"
		if ([data length] < 50)
		{
			NSString* outString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		
			// is the output an error string?
			if ([outString hasPrefix:@"AuthorizationCreate failed with"])
				[userInfo setObject:outString forKey:NTAuthOpenErrorString];
		}
		
		// if we didn't add an error, pass the data
		if (![userInfo objectForKey:NTAuthOpenErrorString])
		{
			if (task == mv_readTask)
				[userInfo setObject:data forKey:NTAuthOpenReadData];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NTAuthOpenCompletionNotification object:[self notificationObject] userInfo:userInfo];
}

@end

@implementation NTAuthOpen (Protocols)

- (void)task_handleTask:(id)task output:(NSData*)output;
{
	[self setReadData:output];
}

- (void)task_handleTask:(id)task errors:(NSData*)output;
{
	NSString* outString = [[[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding] autorelease];

	NSLog(@"authopen err: %@", outString);
}

- (void)task_handleTask:(id)task finished:(NSNumber*)result;
{
	[self postNotification:task];

	if (task == mv_writeTask)
		[self disposeWriteTask];
	else if (task == mv_readTask)
		[self disposeReadTask];
		
	// these are one shot objects, when done, release
	[self autorelease];
}

@end
