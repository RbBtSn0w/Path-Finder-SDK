//
//  NTOperation.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTOperation.h"

@implementation NTOperation

@synthesize delegate;
@synthesize parameter;
@synthesize result;

+ (NTOperation*)operation:(id<NTOperationDelegateProtocol>)theDelegate
				parameter:(id)theParameter;
{
	NTOperation* result = [[[self class] alloc] init];
	
	result.delegate = theDelegate;
	result.parameter = theParameter;
	
	return [result autorelease];
}

- (void)dealloc;
{
	if (self.delegate)
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];

	self.parameter = nil;
	self.result = nil;
	
	[super dealloc];
}
	 
- (void)clearDelegate;
{
	[self cancel];  // cancel here incase still running and we are clearing delegate because we don't need it
	
	self.delegate = nil;
}

// must subclass to do work
- (void)main;
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{		
		@try {
			[self doMain];
		}
		@catch (NSException * e) {
			NSLog(@"-[%@ %@] %@", [self className], NSStringFromSelector(_cmd), [e description]);
		}
		@finally {
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			@try {
				[[self delegate] operation_complete:self];
			}
			@catch (NSException * e) {
				NSLog(@"NTOperation main exception: %@", e);
			}
			@finally {
			}
		});
	}
	[pool release];
}

- (void)doMain;
{
	// must subclass
	[NSException raise:@"must subclass" format:@"%@", NSStringFromClass([self class])];
}

@end
