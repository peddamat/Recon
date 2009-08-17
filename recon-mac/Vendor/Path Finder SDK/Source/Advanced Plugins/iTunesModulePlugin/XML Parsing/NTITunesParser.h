//
//  NTITunesParser.h
//  iLike
//
//  Created by Steve Gehrman on 2/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTITunesTrackElement, NTITunesParser, NTXMLParser, NTITunesPlaylistElement;

@protocol NTITunesParserDelegateProtocol <NSObject>
- (void)parser:(NTITunesParser*)parser started:(BOOL)started;  // NO when finished
- (void)parser:(NTITunesParser*)parser foundTrack:(NSDictionary*)track;
- (void)parser:(NTITunesParser*)parser foundPlaylist:(NSDictionary*)playlist;
@end

@interface NTITunesParser : NSObject 
{
	NSURL* mFileURL;

	id<NTITunesParserDelegateProtocol> mDelegate;
	
	NTXMLParser *mXMLParser;
	int mStep;
	
	NTITunesTrackElement* mTrack;
	NTITunesPlaylistElement* mPlaylist;
		
	NSMutableString* mCurrentString;
}

+ (NTITunesParser*)parser:(NSString*)sourcePath
	delegate:(id<NTITunesParserDelegateProtocol>)delegate;

- (void)clearDelegate;
- (void)parse;
@end

@interface NTITunesParser (elementCallbacks)
// called from the element when it's done getting a dictionary
- (void)finishedTrack:(NTXMLParser *)parser;
- (void)finishedPlaylist:(NTXMLParser *)parser ignore:(BOOL)ignore;
@end
