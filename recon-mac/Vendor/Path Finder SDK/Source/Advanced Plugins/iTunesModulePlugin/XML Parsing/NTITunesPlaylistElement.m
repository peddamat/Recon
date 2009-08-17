//
//  NTITunesPlaylistElement.m
//  iLike
//
//  Created by Steve Gehrman on 2/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTITunesPlaylistElement.h"
#import "NTITunesParser.h"

@interface NTITunesPlaylistElement (Private)
- (NSMutableDictionary *)dictionary;
- (void)setDictionary:(NSMutableDictionary *)theDictionary;

- (NSString *)key;
- (void)setKey:(NSString *)theKey;

- (NTITunesParser *)parser;
- (void)setParser:(NTITunesParser *)theParser;

- (int)step;
- (void)setStep:(int)theStep;

- (NSMutableArray *)trackIDs;
- (void)setTrackIDs:(NSMutableArray *)theTrackIDs;

- (NSMutableString *)currentString;
- (void)setCurrentString:(NSMutableString *)theCurrentString;

- (BOOL)shouldIgnorePlaylist;
@end

enum
{
	kGatheringAttributes_step,
	kGatheringTrackIDs_step,
};

@implementation NTITunesPlaylistElement

+ (NTITunesPlaylistElement*)element:(NTITunesParser *)parser;
{
    NTITunesPlaylistElement* result = [[NTITunesPlaylistElement alloc] init];
	
    [result setParser:parser];
	
    return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDictionary:nil];
    [self setParser:nil];
	[self setCurrentString:nil];
	[self setKey:nil];
	[self setTrackIDs:nil];

    [super dealloc];
}

- (NSDictionary*)info;
{
	return [NSDictionary dictionaryWithDictionary:[self dictionary]];
}

@end

@implementation NTITunesPlaylistElement (Private)

//---------------------------------------------------------- 
//  step 
//---------------------------------------------------------- 
- (int)step
{
    return mStep;
}

- (void)setStep:(int)theStep
{
    mStep = theStep;
}

//---------------------------------------------------------- 
//  dictionary 
//---------------------------------------------------------- 
- (NSMutableDictionary *)dictionary
{
	if (!mDictionary)
		[self setDictionary:[NSMutableDictionary dictionaryWithCapacity:10]];
	
    return mDictionary; 
}

- (void)setDictionary:(NSMutableDictionary *)theDictionary
{
    if (mDictionary != theDictionary)
    {
        [mDictionary release];
        mDictionary = [theDictionary retain];
    }
}

//---------------------------------------------------------- 
//  currentString 
//---------------------------------------------------------- 
- (NSMutableString *)currentString
{
	if (!mCurrentString)
		[self setCurrentString:[NSMutableString stringWithCapacity:100]];
	
    return mCurrentString; 
}

- (void)setCurrentString:(NSMutableString *)theCurrentString
{
    if (mCurrentString != theCurrentString)
    {
        [mCurrentString release];
        mCurrentString = [theCurrentString retain];
    }
}

//---------------------------------------------------------- 
//  key 
//---------------------------------------------------------- 
- (NSString *)key
{
    return mKey; 
}

- (void)setKey:(NSString *)theKey
{
    if (mKey != theKey)
    {
        [mKey release];
        mKey = [theKey retain];
    }
}

//---------------------------------------------------------- 
//  parser 
//---------------------------------------------------------- 
- (NTITunesParser *)parser
{
    return mParser; 
}

- (void)setParser:(NTITunesParser *)theParser
{
    if (mParser != theParser)
    {
        [mParser release];
        mParser = [theParser retain];
    }
}

//---------------------------------------------------------- 
//  trackIDs 
//---------------------------------------------------------- 
- (NSMutableArray *)trackIDs
{
	if (!mTrackIDs)
		[self setTrackIDs:[NSMutableArray array]];
	
    return mTrackIDs; 
}

- (void)setTrackIDs:(NSMutableArray *)theTrackIDs
{
    if (mTrackIDs != theTrackIDs)
    {
        [mTrackIDs release];
        mTrackIDs = [theTrackIDs retain];
    }
}

- (BOOL)shouldIgnorePlaylist;
{
	// ## disabled
	return NO;
	
	static NSArray *shared = nil;
	if (!shared)
	{
		shared = [[NSArray arrayWithObjects:			
				   @"Smart Info",
				   @"Smart Criteria",
				   @"Master",
				   @"Audiobooks",
				   @"Movies",
				   @"Music",
				   @"Party Shuffle",
				   @"Podcasts",
				   @"Purchased Music",
				   @"TV Shows",
				   @"Folder",  // parent playlist
				   nil] retain];
	}
	
	NSString* key;
	
	for (key in shared)
	{
		if ([[self dictionary] objectForKey:key])
			return YES;
	}
	
	// ignore playlists with more than 1000 tracks
	if ([[self trackIDs] count] > 1000)
		return YES;
		
	// ignore playlists with these names
	static NSArray *sharedNames = nil;
	if (!sharedNames)
	{
		sharedNames = [[NSArray arrayWithObjects:			
			@"Videos",
			@"Video",
			@"Podcasts",
			@"Music",
			@"Movies",
			@"Audiobooks",
			@"TV Shows",
			@"CD",
			@"iTrip Stations",
			@"Purchased",
			@"Library",
			@"My Top Rated",
			@"Music Videos",
			nil] retain];
	}
	
	if ([sharedNames containsObject:[[self dictionary] objectForKey:@"Name"]])
		return YES;
	
	return NO;
}

@end

@implementation NTITunesPlaylistElement (Protocols)

// NTXMLParserDelegateProtocol

- (void)parserDidStartDocument:(NTXMLParser *)parser;
{
}

- (void)parserDidEndDocument:(NTXMLParser *)parser;
{
}

- (void)parser:(NTXMLParser *)parser 
        didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict;
{
	// clear current string
	[[self currentString] setString:@""];
	
	if ([elementName isEqualToString:@"array"])
	{		
		// was our key "Playlist Items"?
		[self setStep:kGatheringTrackIDs_step];
	}
}

- (void)parser:(NTXMLParser *)parser
 foundCharacters:(NSString *)string 
{
    [[self currentString] appendString:string];
}

- (void)parser:(NTXMLParser *)parser
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{	
	// are we done?
	if ([elementName isEqualToString:@"dict"])
	{
		if ([self step] == kGatheringAttributes_step)
		{
			// add the trackIDs to our dictionary
			[[self dictionary] setObject:[self trackIDs] forKey:@"tracks"];			
			
			[[self parser] finishedPlaylist:parser ignore:[self shouldIgnorePlaylist]];
		}
	}
	else if ([elementName isEqualToString:@"key"])
		[self setKey:[NSString stringWithString:[self currentString]]];
	else if ([elementName isEqualToString:@"integer"])
	{
		if ([self step] == kGatheringTrackIDs_step)
			[[self trackIDs] addObject:[NSString stringWithString:[self currentString]]];
		else
			[[self dictionary] setObject:[NSString stringWithString:[self currentString]] forKey:[self key]];
	}
	else if ([elementName isEqualToString:@"true"])
		[[self dictionary] setObject:elementName forKey:[self key]];
	else if ([elementName isEqualToString:@"data"])
		[[self dictionary] setObject:elementName forKey:[self key]];
	else if ([elementName isEqualToString:@"string"])
		[[self dictionary] setObject:[NSString stringWithString:[self currentString]] forKey:[self key]];
	else if ([elementName isEqualToString:@"date"])		
		[[self dictionary] setObject:[NSString stringWithString:[self currentString]] forKey:[self key]];
	else if ([elementName isEqualToString:@"array"])
	{
		if ([self step] == kGatheringTrackIDs_step)
			[self setStep:kGatheringAttributes_step]; // go back to doing attributes
	}
}

@end
