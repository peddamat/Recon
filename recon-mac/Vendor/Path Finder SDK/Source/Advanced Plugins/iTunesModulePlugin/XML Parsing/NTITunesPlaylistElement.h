//
//  NTITunesPlaylistElement.h
//  iLike
//
//  Created by Steve Gehrman on 2/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTXMLParser.h"

@class NTITunesParser;

@interface NTITunesPlaylistElement : NSObject 
{
	NTITunesParser *mParser;
	NSMutableDictionary* mDictionary;

	int mStep;
	NSMutableArray* mTrackIDs;
	
	NSString* mKey;
	NSMutableString* mCurrentString;
}

+ (NTITunesPlaylistElement*)element:(NTITunesParser *)parser;

- (NSDictionary *)info;
@end

@interface NTITunesPlaylistElement (Protocols) <NTXMLParserDelegateProtocol>
@end

