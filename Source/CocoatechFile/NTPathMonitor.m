//
//  NTPathMonitor.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 5/6/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTPathMonitor.h"
#import "NTPathMonitorDatabase.h"
#import "NTFileEnvironment.h"

@interface NTPathMonitor ()
@property (nonatomic, retain) NTPathMonitorDatabase* database;
@property (nonatomic, retain) NSMutableDictionary* clientKeyMap;
@end

@implementation NTPathMonitor

@synthesize database, clientKeyMap;

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.database = nil;
	self.clientKeyMap = nil;
	
    [super dealloc];
}

+ (NTPathMonitor*)pathMonitor;
{
	NTPathMonitor* result = [[NTPathMonitor alloc] init];
	
	result.database = [NTPathMonitorDatabase database];
	result.clientKeyMap = [NSMutableDictionary dictionary];
	
	return [result autorelease];
}

- (void)addClientID:(id)theClientID forPath:(NSString*)thePath;
{
	if (![thePath length])
		return;
	
	// make array of sub paths and add my client id to each one
	NSArray* pathComponents = [thePath pathComponents];
	NSMutableDictionary* theDict;
	NSMutableArray* subPaths = [NSMutableArray array];
	NSMutableArray* subPathNames = [NSMutableArray array];

	NSString* aSubPath = @"";
	[subPaths addObject:aSubPath];  // always going to have the root
	
	for (NSString* aComponent in pathComponents)
	{
		[subPathNames addObject:aComponent];
		
		aSubPath = [aSubPath stringByAppendingPathComponent:aComponent];
		[subPaths addObject:aSubPath];
	}
	
	// clientPathMap has a subPath as a key and the object is a mutable dictionary with a nameToTest as key and an array of clients for the object
	NSMutableArray* theSubsToRemove = [NSMutableArray array];
	NSMutableArray* theNamesToTest = [NSMutableArray array];
	
	NSUInteger theIndex=0;
	for (NSString* theSub in subPaths)
	{
		NSString* nameToTest = [subPathNames safeObjectAtIndex:theIndex++];
		if (nameToTest)
		{
			[self.database setObject:theClientID forKey:theSub forKey:nameToTest];
			
			[theSubsToRemove addObject:theSub];
			[theNamesToTest addObject:nameToTest];
		}
	}
	
	[self.clientKeyMap setObject:[NSArray arrayWithObjects:theClientID, theSubsToRemove, theNamesToTest, nil] forKey:theClientID];
}

- (void)removeClientID:(id)theClientID;
{
	NSArray* clientKeys = [self.clientKeyMap objectForKey:theClientID];
	
	if ([clientKeys count] == 3)
	{
		NSArray *theSubs = [clientKeys objectAtIndex:1];
		NSArray *theNames = [clientKeys objectAtIndex:2];
		
		for (NSUInteger i=0;i<[theSubs count];i++)
			[self.database removeObject:[clientKeys objectAtIndex:0] forKey:[theSubs objectAtIndex:i] forKey:[theNames objectAtIndex:i]];
		
		[self.clientKeyMap removeObjectForKey:theClientID];
	}
	else
		NSLog(@"-[%@ %@] failed to find client: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), theClientID);	
}

// returns client ids that have changed
- (NSArray*)processPaths:(NSArray*)thePaths mountPoint:(NSString*)theMountPoint;
{
	NSMutableArray* result = nil;
	
	for (NSString *theSub in thePaths)
	{
		NSArray* theKeys = [self.database keysForKey:theSub];
		
		if ([theKeys count])
		{
			NSString* fullPath = [theMountPoint stringByAppendingPathComponent:theSub];

			for (id theKey in theKeys)
			{				
				NSString* testPath = [fullPath stringByAppendingPathComponent:theKey];
				
				if (![[NSFileManager defaultManager] fileExistsAtPath:testPath])
				{
					NSArray* theClientIDs = [self.database objectsForKey:theSub forKey:theKey];
					
					if ([theClientIDs count])
					{
						if (FENV(logFSEvents))
							[[NTFileEnvironment sharedInstance] notify_FSEvent:@"rename" eventInfo:testPath];
						
						if (!result)
							result = [NSMutableArray array];
						
						[result addObjectsFromArray:theClientIDs];
					}
					else
						NSLog(@"renamed: client IDS EMPTY?: %@", testPath);
				}
				else
				{
					if (FENV(logFSEvents))
						[[NTFileEnvironment sharedInstance] notify_FSEvent:@"name ok" eventInfo:testPath];
				}
			}
		}
	}
	
	return result;
}

@end
