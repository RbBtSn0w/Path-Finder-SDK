//
//  NTFileListMonitorThread.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTFileListMonitorThread : NTThreadRunnerParam
{
    NSArray* descs;
	NSDictionary *rsrcFileTable;
	
    BOOL descsRemoved;
	BOOL descsModified;
	BOOL networkVolume;
}

@property (readonly, retain) NSArray* descs;
@property (readonly, retain) NSDictionary *rsrcFileTable;
@property (readonly, assign) BOOL descsRemoved;
@property (readonly, assign) BOOL descsModified;

+ (NTThreadRunner*)thread:(NSArray*)descs
			rsrcFileTable:(NSDictionary *)rsrcFileTable
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;

@end
