//
//  NTITunesDataModel.h
//  iLike
//
//  Created by Steve Gehrman on 11/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// used for all access to iTunes XML file.  
// Thread safe

@class NTITunesXMLFile;

@interface NTITunesDataModel : NSObject 
{
	// NTITunesXMLFile monitors the file for changes and tells us to update
	NTITunesXMLFile *ITunesFile;
	BOOL threadRunning;

	// minimal data extracted from itunes.xml to keep mem usage down
	NSArray* artists; // array of dictionaries
	NSArray* playlists; // array of dictionaries
	NSArray* list; // current list, either artists or playlists
	
	// built while parsing, not cached, we need to build up track
	NSMutableDictionary* mutableArtists;
	NSMutableDictionary* mutablePlaylists;
	NSMutableDictionary* mutableTracks;
	
	NSArray* listSortDescriptors;
	NSArray* trackSortDescriptors;
	
	NSArray* listTypes;
	NSString* mSelectedListType;
}

+ (NTITunesDataModel*)model;

@end
