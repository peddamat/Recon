//
//  NTITunesParser.m
//  iLike
//
//  Created by Steve Gehrman on 2/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTITunesParser.h"
#import "NTITunesTrackElement.h"
#import "NTITunesTrackElementDict.h"
#import "NTITunesPlaylistElement.h"
#import "GBUtilities.h"
#import "NTXMLParser.h"

@interface NTITunesParser (Private)
- (NSURL *)fileURL;
- (void)setFileURL:(NSURL *)theFileURL;

- (NTXMLParser *)XMLParser;
- (void)setXMLParser:(NTXMLParser *)theXMLParser;

- (NSMutableString *)currentString;
- (void)setCurrentString:(NSMutableString *)theCurrentString;

- (NTITunesTrackElement *)track;
- (void)setTrack:(NTITunesTrackElement *)theTrack;

- (id<NTITunesParserDelegateProtocol>)delegate;
- (void)setDelegate:(id<NTITunesParserDelegateProtocol>)theDelegate;

- (NTITunesPlaylistElement *)playlist;
- (void)setPlaylist:(NTITunesPlaylistElement *)thePlaylist;

- (void)startParser;

- (int)step;
- (void)setStep:(int)theStep;
@end

@interface NTITunesParser (Protocols) <NTXMLParserDelegateProtocol>
@end

enum
{
	kUndefined_step,

	kGatheringPlaylists_step,
	kGatheringTracks_step,
};

@implementation NTITunesParser

+ (NTITunesParser*)parser:(NSString*)sourcePath
				 delegate:(id<NTITunesParserDelegateProtocol>)delegate;
{
	NTITunesParser* result = [[NTITunesParser alloc] init];
		
	[result setDelegate:delegate];
	
	// set some parameters
	if (sourcePath)
		[result setFileURL:[NSURL fileURLWithPath:sourcePath]];
		
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	if ([self delegate])
		[NSException raise:@"must clear delegate" format:@"%@", NSStringFromSelector(_cmd)];
	
    [self setTrack:nil];
	[self setPlaylist:nil];
	[self setXMLParser:nil];
    [self setCurrentString:nil];
    [self setFileURL:nil];

    [super dealloc];
}

- (void)parse;
{
	[self startParser];
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
}

@end

@implementation NTITunesParser (Protocols)

// NTXMLParserDelegateProtocol
- (void)parserDidStartDocument:(NTXMLParser *)parser
{
	[[self delegate] parser:self started:YES];
}

// <playlist id='ABC456'><name>90's music</name><source>iTunes</source><items>i957,i958,i957</items></playlist>
// add playlists

- (void)parserDidEndDocument:(NTXMLParser *)parser
{
	[[self delegate] parser:self started:NO];
}

- (void)parser:(NTXMLParser *)parser 
        didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict;
{	
	// clear current string
	[[self currentString] setString:@""];

	switch ([self step])
	{
		case kUndefined_step:
			break;
		case kGatheringTracks_step:
		{
			if ([elementName isEqualToString:@"dict"])
			{						
				// Creation of element sets child as delegate (see below)
				[self setTrack:[NTITunesTrackElement element:self]];    
				
				// set track as the delegate, it will give control back to us when it's done
				[parser setDelegate:[self track]];
			}			
		}
			break;
		case kGatheringPlaylists_step:
		{
			if ([elementName isEqualToString:@"dict"])
			{						
				// Creation of element sets child as delegate (see below)
				[self setPlaylist:[NTITunesPlaylistElement element:self]];    
				
				// set track as the delegate, it will give control back to us when it's done
				[parser setDelegate:[self playlist]];
			}					
		}
			break;
		default:
			break;
	}
}

- (void)parser:(NTXMLParser *)parser
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
	switch ([self step])
	{
		case kUndefined_step:
		{
			if ([elementName isEqualToString:@"key"])
			{
				if ([[self currentString] isEqualToString:@"Playlists"])
					[self setStep:kGatheringPlaylists_step];
				else if ([[self currentString] isEqualToString:@"Tracks"])
					[self setStep:kGatheringTracks_step];
			}						
		}
			break;			
		case kGatheringTracks_step:
		{
			if ([elementName isEqualToString:@"dict"])
				[self setStep:kUndefined_step];
		}
			break;
		case kGatheringPlaylists_step:
		{
			if ([elementName isEqualToString:@"array"])
				[self setStep:kUndefined_step];
		}
			break;
		default:
			break;
	}
}

- (void)parser:(NTXMLParser *)parser
foundCharacters:(NSString *)string 
{
	[[self currentString] appendString:string];
}

@end

@implementation NTITunesParser (Private)

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTITunesParserDelegateProtocol>)delegate
{
    return mDelegate; 
}

- (void)setDelegate:(id<NTITunesParserDelegateProtocol>)theDelegate
{
    if (mDelegate != theDelegate)
        mDelegate = theDelegate;
}

- (void)startParser;
{
	[self setXMLParser:[NTXMLParser xmlParser:[[self fileURL] path]]];
	[[self XMLParser] parse];
}

//---------------------------------------------------------- 
//  fileURL 
//---------------------------------------------------------- 
- (NSURL *)fileURL
{	
    return mFileURL; 
}

- (void)setFileURL:(NSURL *)theFileURL
{
    if (mFileURL != theFileURL)
    {
        [mFileURL release];
        mFileURL = [theFileURL retain];
    }
}

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
//  XMLParser 
//---------------------------------------------------------- 
- (NTXMLParser *)XMLParser
{
    return mXMLParser; 
}

- (void)setXMLParser:(NTXMLParser *)theXMLParser
{
    if (mXMLParser != theXMLParser)
    {
		[[self XMLParser] setDelegate:nil];

        [mXMLParser release];
        mXMLParser = [theXMLParser retain];
		
		[[self XMLParser] setDelegate:self];
    }
}

//---------------------------------------------------------- 
//  track 
//---------------------------------------------------------- 
- (NTITunesTrackElement *)track
{
    return mTrack; 
}

- (void)setTrack:(NTITunesTrackElement *)theTrack
{
    if (mTrack != theTrack)
    {
        [mTrack release];
        mTrack = [theTrack retain];
    }
}

//---------------------------------------------------------- 
//  playlist 
//---------------------------------------------------------- 
- (NTITunesPlaylistElement *)playlist
{
    return mPlaylist; 
}

- (void)setPlaylist:(NTITunesPlaylistElement *)thePlaylist
{
    if (mPlaylist != thePlaylist)
    {
        [mPlaylist release];
        mPlaylist = [thePlaylist retain];
    }
}

@end

@implementation NTITunesParser (elementCallbacks)

- (void)finishedTrack:(NTXMLParser *)parser;
{
	[parser setDelegate:self];  // set ourselves back to the delegate
	
	NSDictionary *info = [[self track] info];
	
	// tell delegate if this is a music track only
	if ([NTITunesTrackElementDict isMusic:info])
		[[self delegate] parser:self foundTrack:info];
	
	// get rid of track and autorelease pool
    [self setTrack:nil];
}

- (void)finishedPlaylist:(NTXMLParser *)parser ignore:(BOOL)ignore;
{
	[parser setDelegate:self];  // ser ourselves back to the delegate
	
	if (!ignore)
	{
		NSDictionary* info = [[self playlist] info];

		// tell delegate
		[[self delegate] parser:self foundPlaylist:info];
	}
	
	// get rid of track and autorelease pool
    [self setPlaylist:nil];
}

@end

