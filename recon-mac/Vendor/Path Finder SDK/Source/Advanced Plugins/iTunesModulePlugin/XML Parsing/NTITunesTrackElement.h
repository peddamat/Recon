//
//  NTITunesTrackElement.h
//  iLike
//
//  Created by Steve Gehrman on 2/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTXMLParser.h"

@class NTITunesParser;

@interface NTITunesTrackElement : NSObject 
{
	NTITunesParser *mParser;
	NSMutableDictionary* mDictionary;
	
	NSString* mKey;
	NSMutableString* mCurrentString;
}

+ (NTITunesTrackElement*)element:(NTITunesParser *)parser;

- (NSDictionary *)info;

@end

@interface NTITunesTrackElement (Protocols) <NTXMLParserDelegateProtocol>
@end

