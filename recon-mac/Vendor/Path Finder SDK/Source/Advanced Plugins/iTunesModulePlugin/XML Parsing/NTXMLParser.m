//
//  NTXMLParser.m
//  iLike
//
//  Created by Steve Gehrman on 2/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NTXMLParser.h"
#include <libxml/parser.h>

@interface NTXMLParser (Private)
- (NSString *)path;
- (void)setPath:(NSString *)thePath;
@end

static void startDocumentHandler(void *user_data);
static void endDocumentHandler(void *user_data);
static void charactersHandler(void *user_data, const xmlChar *ch, int len);
static void startElementHandler(void *user_data, const xmlChar *name, const xmlChar **attrs);
static void endElementHandler(void *user_data, const xmlChar *name);

@implementation NTXMLParser

+ (NTXMLParser*)xmlParser:(NSString*)path;
{	
	NTXMLParser *result = [[NTXMLParser alloc] init];
	
	[result setPath:path];
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setPath:nil];
    [super dealloc];
}

- (void)parse;
{
	xmlSAXHandler sax;
    memset(&sax, 0, sizeof(sax));
	sax.startDocument = startDocumentHandler;
    sax.endDocument = endDocumentHandler;
	sax.characters = charactersHandler;
    sax.startElement = startElementHandler;
    sax.endElement = endElementHandler;
	sax.initialized = XML_SAX2_MAGIC;
	
	// this was crashing.  I think iTunes is writing the file during a parse
	// xmlSAXUserParseFile(&sax, self, [[NSFileManager defaultManager] fileSystemRepresentationWithPath:[self path]]);	
	
	NSData *data = [NSData dataWithContentsOfFile:[self path]];
	xmlSAXUserParseMemory(&sax, self, [data bytes], [data length]);
}

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTXMLParserDelegateProtocol>)delegate
{
    return mDelegate; 
}

- (void)setDelegate:(id<NTXMLParserDelegateProtocol>)theDelegate
{
    if (mDelegate != theDelegate)
        mDelegate = theDelegate;  // not retained
}

@end

@implementation NTXMLParser (Private)

//---------------------------------------------------------- 
//  path 
//---------------------------------------------------------- 
- (NSString *)path
{
    return mPath; 
}

- (void)setPath:(NSString *)thePath
{
    if (mPath != thePath)
    {
        [mPath release];
        mPath = [thePath retain];
    }
}

@end

//////////////////////////////////////////////////////////////////////
// callbacks

static void startDocumentHandler(void *user_data)
{
	NTXMLParser* parser = (NTXMLParser*)user_data;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{
		[[parser delegate] parserDidStartDocument:parser];
	}
	[pool release];
}

static void endDocumentHandler(void *user_data)
{
	NTXMLParser* parser = (NTXMLParser*)user_data;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{
		[[parser delegate] parserDidEndDocument:parser];
	}
	[pool release];
}

static void charactersHandler(void *user_data, const xmlChar *ch, int len)
{
	NTXMLParser* parser = (NTXMLParser*)user_data;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{
		// NSString* string = [[NSString alloc] initWithBytesNoCopy:(void*)ch length:len encoding:NSUTF8StringEncoding freeWhenDone:NO];
		NSString* string = [[NSString alloc] initWithBytes:(void*)ch length:len encoding:NSUTF8StringEncoding];
		
		[[parser delegate] parser:parser foundCharacters:string];
		
		[string release];
	}
	[pool release];
}

static void startElementHandler(void *user_data, const xmlChar *name, const xmlChar **attrs)
{
	NTXMLParser* parser = (NTXMLParser*)user_data;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{
		// NSString* string = [[NSString alloc] initWithBytesNoCopy:(void*)name length:strlen((const char *)name) encoding:NSUTF8StringEncoding freeWhenDone:NO];
		NSString* string = [[NSString alloc] initWithBytes:(void*)name length:strlen((const char *)name) encoding:NSUTF8StringEncoding];

		[[parser delegate] parser:parser 
				didStartElement:string 
				   namespaceURI:nil 
				  qualifiedName:nil 
					 attributes:nil];	
		
		[string release];
	}
	[pool release];
}

static void endElementHandler(void *user_data, const xmlChar *name)
{
	NTXMLParser* parser = (NTXMLParser*)user_data;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{
		// NSString* string = [[NSString alloc] initWithBytesNoCopy:(void*)name length:strlen((const char *)name) encoding:NSUTF8StringEncoding freeWhenDone:NO];
		NSString* string = [[NSString alloc] initWithBytes:(void*)name length:strlen((const char *)name) encoding:NSUTF8StringEncoding];

		[[parser delegate] parser:parser
				  didEndElement:string 
				   namespaceURI:nil 
				  qualifiedName:nil];	
		
		[string release];
	}
	[pool release];
}
