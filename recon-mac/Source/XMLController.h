//
//  XMLController.h
//  recon
//
//  Created by Sumanth Peddamatham on 6/30/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//
//  http://developer.apple.com/documentation/Cocoa/Conceptual/XMLParsing/Articles/UsingParser.html
//

#import <Cocoa/Cocoa.h>

@class Session;
@class Host;
@class Port;

@interface XMLController : NSObject {
   NSXMLParser *addressParser;
   NSMutableString *currentStringValue;
   
   Session *currentSession;
   Host *currentHost;
   Port *currentPort;
   
   BOOL inRunstats;
   BOOL onlyReadProgress;
}

+ (void) readResults: (NSArray *)sessionDirectory 
          forSession: (Session *)session inManagedObjectContext:(NSManagedObjectContext *)context;

- (void)openXMLFile;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)parseXMLFile:(NSString *)pathToFile inSession:(Session *)session onlyReadProgress:(BOOL)oReadProgress;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict ;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;

@end
