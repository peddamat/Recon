//
//  NTITunesDataModel.m
//  iLike
//
//  Created by Steve Gehrman on 11/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTITunesDataModel.h"
#import "GBUtilities.h"
#import "NTITunesTrack.h"
#import "NTITunesXMLFile.h"
#import "NTITunesParser.h"

@interface NTITunesDataModel (Private)
- (void)parseXML;

- (NSString *)selectedListType;
- (void)setSelectedListType:(NSString *)theSelectedListType;
@end

@interface NTITunesDataModel (Protocols) <NTITunesXMLFileDelegateProtocol, NTITunesParserDelegateProtocol>
@end

@implementation NTITunesDataModel

@synthesize mutableArtists;
@synthesize mutablePlaylists;
@synthesize mutableTracks, artists, playlists;
@synthesize listSortDescriptors;
@synthesize trackSortDescriptors, list, ITunesFile, listTypes, sentDelayedUpdateNotification;

+ (NTITunesDataModel*)model;
{
	NTITunesDataModel* result = [[NTITunesDataModel alloc] init];
	
	[result setMutablePlaylists:[NSMutableDictionary dictionary]];
	[result setMutableArtists:[NSMutableDictionary dictionary]];
	[result setMutableTracks:[NSMutableDictionary dictionary]];
	[result setTrackSortDescriptors:[NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(compare:)] autorelease], nil]];
	[result setListSortDescriptors:[NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease], nil]];

	[result setListTypes:[NSArray arrayWithObjects:@"Playlists", @"Artists", nil]];
	[result setSelectedListType:[[result listTypes] objectAtIndex:0]];
	[result setITunesFile:[NTITunesXMLFile file:result]];
	
	// start xml parsing
	[result parseXML];
		
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.mutableArtists = nil;
    self.mutablePlaylists = nil;
    self.mutableTracks = nil;
	self.artists = nil;
	self.playlists = nil;
	self.listSortDescriptors = nil;
    self.trackSortDescriptors = nil;
	self.list = nil;
	self.listTypes = nil;
	
	[self.ITunesFile clearDelegate];
	self.ITunesFile = nil;
	
    [self setSelectedListType:nil];
	
    [super dealloc];
}

@end

@implementation NTITunesDataModel (Private)

- (void)updateList;
{
	if ([[self listTypes] count])
	{
		if ([self selectedListType] == [[self listTypes] objectAtIndex:0])
			[self setList:[self playlists]];
		else
			[self setList:[self artists]];
	}
}

- (void)parseXML;
{
	[NSThread detachNewThreadSelector:@selector(threadProc:) toTarget:self withObject:[[self ITunesFile] databasePath]];
}

- (void)threadProc:(NSString*)databasePath;
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
	NTITunesParser *parser = [NTITunesParser parser:databasePath
										   delegate:self];
	
	// parse calls our callbacks to collect data
	[parser parse];
	[parser clearDelegate]; 
	
	NSArray *theArtists = [NSArray arrayWithArray:[[self mutableArtists] allValues]];
	[self setMutableArtists:nil];  // no longer needed

	NSArray *thePlaylists = [NSArray arrayWithArray:[[self mutablePlaylists] allValues]];
	[self setMutablePlaylists:nil];  // no longer needed

	[self setMutableTracks:nil];  // no longer needed, just used to build playlists tracks	
	
	// set result on main thread
	[self performSelectorOnMainThread:@selector(setArtists:) withObject:theArtists waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(setPlaylists:) withObject:thePlaylists waitUntilDone:NO];
	
	// update
	[self performSelectorOnMainThread:@selector(updateList) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)sendUpdateNotificationAfterDelay;
{
	[self setSentDelayedUpdateNotification:NO];
	
	[self parseXML];

	// send out a notification that we updated our data
	[[NSNotificationCenter defaultCenter] postNotificationName:NTITunesDataModelNotification object:self];
}

//---------------------------------------------------------- 
//  selectedListType 
//---------------------------------------------------------- 
- (NSString *)selectedListType
{
    return mSelectedListType; 
}

- (void)setSelectedListType:(NSString *)theSelectedListType
{
    if (mSelectedListType != theSelectedListType)
    {
        [mSelectedListType release];
        mSelectedListType = [theSelectedListType retain];
		
		[self updateList];
    }
}

@end

// called on main thread by iTunesXMLFile
// NTITunesXMLFileDelegateProtocol

@implementation NTITunesDataModel (Protocols)

// called on main thread
- (void)iTunesXMLFile_wasUpdated:(NTITunesXMLFile*)file;
{
	if (![self sentDelayedUpdateNotification])
	{
		[self setSentDelayedUpdateNotification:YES];
		
		[self performSelector:@selector(sendUpdateNotificationAfterDelay) withObject:nil afterDelay:5];
	}	
}

// NTITunesParserDelegateProtocol
- (void)parser:(NTITunesParser*)parser foundTrack:(NSDictionary*)track;
{
	// first create a stripped down track dictionary.  Just need URL and artist
	NSURL* url = [NTITunesTrack url:track];	
	
	if (url)
	{
		NSString* path = [url path];
		NSString* name = [path lastPathComponent];
		
		NSString* trackID = [NTITunesTrack trackID:track];	
		NSString* artist = [NTITunesTrack artist:track];	

		if (!artist)
			artist = @"unknown";
		
		// add to artists mutable dictionary
		NSString* canonicalArtist = [artist GB_canonicalString];
		
		NSMutableArray* artistTracks = nil;
		NSMutableDictionary* artistInfo = [[self mutableArtists] objectForKey:canonicalArtist];
		if (!artistInfo)
		{
			artistInfo = [NSMutableDictionary dictionary];
			
			// fill in name and empty tracks array
			[artistInfo setObject:artist forKey:@"name"];
			
			artistTracks = [NSMutableArray array];
			[artistInfo setObject:artistTracks forKey:@"tracks"];
			
			[[self mutableArtists] setObject:artistInfo forKey:canonicalArtist];
		}
		else
			artistTracks = [artistInfo objectForKey:@"tracks"];
		
		NSDictionary* trackInfo = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", name, @"name", artist, @"artist", nil];
		
		// add to artistTracks
		[artistTracks addObject:trackInfo];
		
		// now set the info in our mutableTracks dictionary
		[[self mutableTracks] setObject:trackInfo forKey:trackID];
	}
}

- (void)parser:(NTITunesParser*)parser foundPlaylist:(NSDictionary*)playlist;
{
	NSString* name = [playlist objectForKey:@"Name"];
	NSString* playlistID = [playlist objectForKey:@"Playlist ID"];
	NSArray* tracks = [playlist objectForKey:@"tracks"];
	
	if ([name length] && [playlistID length] && [tracks count])
	{
		NSMutableArray* newTracks = [NSMutableArray array];

		// build playlist dictionary.  Convert trackIDs to real trackInfo dictionaries by looking up ids in mutableTracks dict
		NSEnumerator* enumerator = [[playlist objectForKey:@"tracks" ] objectEnumerator];
		NSString* trackID;
		NSDictionary *trackInfo;
		
		while (trackID = [enumerator nextObject])
		{
			trackInfo = [[self mutableTracks] objectForKey:trackID];
			
			if (trackInfo)
				[newTracks addObject:trackInfo];
		}
		
		if ([newTracks count])
		{
			NSDictionary* playlistInfo = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", newTracks, @"tracks" ,nil];
			
			[[self mutablePlaylists] setObject:playlistInfo forKey:[playlist objectForKey:@"Playlist ID"]];
		}
	}
}

- (void)parser:(NTITunesParser*)parser started:(BOOL)started;  // NO when finished
{
}

@end
