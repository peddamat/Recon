//
//  NTITunesTrackElement.m
//  iLike
//
//  Created by Steve Gehrman on 2/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTITunesTrackElement.h"
#import "NTITunesParser.h"

@interface NTITunesTrackElement (Private)
- (NSMutableDictionary *)dictionary;
- (void)setDictionary:(NSMutableDictionary *)theDictionary;

- (NSString *)key;
- (void)setKey:(NSString *)theKey;

- (NTITunesParser *)parser;
- (void)setParser:(NTITunesParser *)theParser;

- (NSMutableString *)currentString;
- (void)setCurrentString:(NSMutableString *)theCurrentString;
@end

@implementation NTITunesTrackElement

+ (NTITunesTrackElement*)element:(NTITunesParser *)parser;
{
    NTITunesTrackElement* result = [[NTITunesTrackElement alloc] init];
	
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

    [super dealloc];
}

- (NSDictionary*)info;
{
	return [NSDictionary dictionaryWithDictionary:[self dictionary]];
}

@end

@implementation NTITunesTrackElement (Private)

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

@end

@implementation NTITunesTrackElement (Protocols)

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
		[[self parser] finishedTrack:parser];
	else if ([elementName isEqualToString:@"key"])
		[self setKey:[NSString stringWithString:[self currentString]]];
	else if ([elementName isEqualToString:@"true"])
		[[self dictionary] setObject:elementName forKey:[self key]];
	else if ([elementName isEqualToString:@"integer"])
		[[self dictionary] setObject:[NSString stringWithString:[self currentString]] forKey:[self key]];
	else if ([elementName isEqualToString:@"string"])
		[[self dictionary] setObject:[NSString stringWithString:[self currentString]] forKey:[self key]];
	else if ([elementName isEqualToString:@"date"])
		[[self dictionary] setObject:[NSString stringWithString:[self currentString]] forKey:[self key]];		
}

@end
