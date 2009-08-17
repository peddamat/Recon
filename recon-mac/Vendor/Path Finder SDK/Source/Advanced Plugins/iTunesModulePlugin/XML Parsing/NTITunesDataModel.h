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

// sent when file refreshed
#define NTITunesDataModelNotification @"NTITunesDataModelNotification" 

@interface NTITunesDataModel : NSObject 
{
	// NTITunesXMLFile monitors the file for changes and tells us to update
	NTITunesXMLFile *ITunesFile;
	BOOL sentDelayedUpdateNotification;

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

@property (retain) NTITunesXMLFile *ITunesFile;
@property (retain) NSMutableDictionary* mutableArtists;
@property (retain) NSMutableDictionary* mutablePlaylists;
@property (retain) NSMutableDictionary* mutableTracks;

@property (retain) NSArray* list;
@property (retain) NSArray* artists;
@property (retain) NSArray* playlists;
@property (retain) NSArray* listSortDescriptors;
@property (retain) NSArray* trackSortDescriptors;
@property (retain) NSArray* listTypes;
@property (assign) BOOL sentDelayedUpdateNotification;

+ (NTITunesDataModel*)model;

@end
