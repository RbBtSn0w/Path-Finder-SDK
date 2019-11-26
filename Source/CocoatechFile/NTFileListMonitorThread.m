//
//  NTFileListMonitorThread.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTFileListMonitorThread.h"
#import "NTVolume.h"

@interface NTFileListMonitorThread ()
@property (retain) NSArray* descs;
@property (retain) NSDictionary *rsrcFileTable;
@property (assign) BOOL descsRemoved;
@property (assign) BOOL descsModified;
@property (assign) BOOL networkVolume;
@end

@interface NTFileListMonitorThread (Private)
- (NSMutableDictionary*)rsrcTableForDescs;
- (NSDictionary*)rsrcFileDescsModified;
@end

@implementation NTFileListMonitorThread

@synthesize descs, networkVolume, descsRemoved, descsModified, rsrcFileTable;

+ (NTThreadRunner*)thread:(NSArray*)descs
			rsrcFileTable:(NSDictionary *)rsrcFileTable
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;
{
    NTFileListMonitorThread* param = [[[NTFileListMonitorThread alloc] init] autorelease];
    
    [param setDescs:descs];
	
	// just use the first item. Just for speed, but I have no idea if this is much of a bottle neck, but should be fine 99.9% of the time
	if ([descs count])
	{
		NTFileDesc* firstDesc = [descs objectAtIndex:0];
		param.networkVolume = [firstDesc isNetwork];
	}
	
	param.rsrcFileTable = rsrcFileTable;
	
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
	self.rsrcFileTable = nil;
	
    [super dealloc];
}

@end

// ---------------------------------------------------------------------------------------

@implementation NTFileListMonitorThread (Thread)

- (BOOL)doThreadProc;
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[[self descs] count]];
	NSEnumerator* enumerator = [[self descs] objectEnumerator];
	NTFileDesc* desc;
	NSDictionary* modifiedRsrcForks = [self rsrcFileDescsModified];
	
	while (desc = [enumerator nextObject])
	{
		if ([[self helper] killed])
			return NO;
		
		// added the isNetwork to pick up label changes on network volumes
		if ([desc hasBeenModified:self.networkVolume] || [desc hasBeenRenamed] || ([modifiedRsrcForks objectForKey:[desc dictionaryKey]] != nil))
		{
			self.descsModified = YES;
			
			desc = [desc freshDesc];
			if (![desc stillExists])
			{
				self.descsRemoved = YES;
				desc = nil;
			}
		}
		
		if (desc)
			[result addObject:desc];
	}
	
	if (self.descsModified)
		[self setDescs:[NSArray arrayWithArray:result]];
	
	return ![[self helper] killed];
}

@end

@implementation NTFileListMonitorThread (Private)

- (NSDictionary*)rsrcFileDescsModified;
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	// first time we need to look for rsrcFileTable
	if (!self.rsrcFileTable)
		self.rsrcFileTable = [NSDictionary dictionaryWithDictionary:[self rsrcTableForDescs]]; // set to empty dict so we know to only do this once
	else 
	{
		NSMutableDictionary * freshRsrcTable = [self rsrcTableForDescs];
		
		// were any rsrc files added or removed?
		if ([self.rsrcFileTable count] != [freshRsrcTable count])
		{
			for (NTFileDesc* desc in [self descs])
			{
				NSDictionary* oldDict = [self.rsrcFileTable objectForKey:[desc dictionaryKey]];
				NSDictionary* newDict = [freshRsrcTable objectForKey:[desc dictionaryKey]];
				
				if ((oldDict && !newDict) || (!oldDict && newDict))
					[result setObject:desc forKey:[desc dictionaryKey]];
			}
		}
		else 
		{
			// were any rsrc files modified?
			for (NTFileDesc* desc in [self descs])
			{
				NTFileDesc* rsrcDict = [self.rsrcFileTable objectForKey:[desc dictionaryKey]];
				
				if ([rsrcDict hasBeenModified])
					[result setObject:desc forKey:[desc dictionaryKey]];
			}
		}
		
		self.rsrcFileTable = freshRsrcTable;
	}

	return result;
}

- (NSMutableDictionary*)rsrcTableForDescs;
{
	NSMutableDictionary* rsrcTable = [NSMutableDictionary dictionary];
	for (NTFileDesc* desc in [self descs])
	{
		if ([[desc volume] supportsForks])
			break; // assume the whole list is OK, might not work in all cases, but faster
		else 
		{
			// scan for ._ file and add that to our list
			NSString* rsrcPath = [desc pathToResourceFork];
			if (rsrcPath)
			{
				NTFileDesc *rsrcDesc = [NTFileDesc descNoResolve:rsrcPath];
				if ([rsrcDesc isValid])
					[rsrcTable setObject:rsrcDesc forKey:[desc dictionaryKey]];
			}
		}
	}
	
	return rsrcTable;
}
@end
