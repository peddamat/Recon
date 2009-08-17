//
//  NTXMLParser.h
//  iLike
//
//  Created by Steve Gehrman on 2/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTXMLParser;

@protocol NTXMLParserDelegateProtocol <NSObject>
- (void)parserDidStartDocument:(NTXMLParser *)parser;

- (void)parserDidEndDocument:(NTXMLParser *)parser;

- (void)parser:(NTXMLParser *)parser 
        didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict;

- (void)parser:(NTXMLParser *)parser
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName;

- (void)parser:(NTXMLParser *)parser
foundCharacters:(NSString *)string;
@end

@interface NTXMLParser : NSObject {
	id<NTXMLParserDelegateProtocol> mDelegate;
	NSString* mPath;
}

+ (NTXMLParser*)xmlParser:(NSString*)path;

// not retained
- (id<NTXMLParserDelegateProtocol>)delegate;
- (void)setDelegate:(id<NTXMLParserDelegateProtocol>)theDelegate;

- (void)parse;
@end

