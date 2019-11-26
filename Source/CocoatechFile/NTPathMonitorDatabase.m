//
//  NTPathMonitorDatabase.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 5/6/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTPathMonitorDatabase.h"

@interface NTPathMonitorDatabase ()
@property (nonatomic, retain) NSMutableDictionary *dictionary;
@end

@interface NTPathMonitorDatabase (Private)
- (NSString*)description;
@end

@implementation NTPathMonitorDatabase

@synthesize dictionary;

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.dictionary = nil;
    [super dealloc];
}

+ (NTPathMonitorDatabase*)database;
{
	NTPathMonitorDatabase* result = [[NTPathMonitorDatabase alloc] init];
	
	result.dictionary = [NSMutableDictionary dictionary];
	
	return [result autorelease];
}

- (void)setObject:(id)theObject forKey:(id)theKey1 forKey:(id)theKey2;
{	
	NSMutableArray* objectArray = [self objectsForKey:theKey1 forKey:theKey2];
	
	NSUInteger theIndex = [objectArray indexOfObjectIdenticalTo:theObject];	
	if (theIndex == NSNotFound)
		[objectArray addObject:theObject];
	else
		NSLog(@"-[%@ %@] object already exists", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)removeObject:(id)theObject forKey:(id)theKey1 forKey:(id)theKey2;  // object must be identical (same pointer) as sent to setObject
{	
	NSMutableArray* objectArray = [self objectsForKey:theKey1 forKey:theKey2];
	
	NSUInteger theIndex = [objectArray indexOfObjectIdenticalTo:theObject];	
	if (theIndex != NSNotFound)
	{
		[objectArray removeObjectAtIndex:theIndex];
		
		// clean up a bit
		if ([objectArray count] == 0)
		{
			// the array of objects is empty, so remove the key from the dictionary
			NSMutableDictionary* theDict = [self.dictionary objectForKey:theKey1];
			[theDict removeObjectForKey:theKey2];
			
			// remove the dictionary too if it's empty
			if ([theDict count] == 0)
				[self.dictionary removeObjectForKey:theKey1];
		}
	}
	else
		NSLog(@"-[%@ %@] object not found", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (NSArray*)keysForKey:(id)theKey1;
{
	NSMutableDictionary* theDict = [self.dictionary objectForKey:theKey1];

	return [theDict allKeys];
}

- (NSMutableArray*)objectsForKey:(id)theKey1 forKey:(id)theKey2;
{
	NSMutableArray* result = nil;
	
	NSMutableDictionary* theDict = [self.dictionary objectForKey:theKey1];
	
	if (!theDict)
	{
		theDict = [NSMutableDictionary dictionary];
		[self.dictionary setObject:theDict forKey:theKey1];
	}
	
	result = [theDict objectForKey:theKey2];
	
	if (!result)
	{
		result = [NSMutableArray array];
		[theDict setObject:result forKey:theKey2];
	}
	
	return result;
}

@end

@implementation NTPathMonitorDatabase (Private)

- (NSString*)description;
{
	// used for debugging only.
	NSUInteger totalSubs = 0;
	NSUInteger totalNames = 0;
	NSUInteger totalClients = 0;
	NSArray* theKeys = [self.dictionary allKeys];
	
	totalSubs = [theKeys count];
	
	for (id theKey in theKeys)
	{
		NSMutableDictionary* theDict = [self.dictionary objectForKey:theKey];
		
		NSArray* theClientArrays = [theDict allValues];
		
		totalNames += [theClientArrays count];
		
		for (NSArray *clientArray in theClientArrays)
			totalClients += [clientArray count];
	}
	
	return [NSString stringWithFormat:@"subs(%d)names(%d)clients(%d)", totalSubs, totalNames, totalClients];
}

@end


