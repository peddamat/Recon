//
//  XMLController.m
//  nmapX
//
//  Created by Sumanth Peddamatham on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "XMLController.h"


@implementation XMLController

- (void)parseXMLFile:(NSString *)pathToFile inSession:(Session *)session onlyReadProgress:(BOOL)onlyReadProgress
{   
   BOOL success;
   NSURL *xmlURL = [NSURL fileURLWithPath:pathToFile];
   
   inRunstats = FALSE;
   onlyReadProgress = onlyReadProgress;
   
   // Save current session
   currentSession = session;
   
   if (addressParser) // addressParser is an NSXMLParser instance variable
      [addressParser release];
   
   addressParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
   [addressParser setDelegate:self];
   [addressParser setShouldResolveExternalEntities:YES];
   success = [addressParser parse]; // return value not used
   // if not successful, delegate is informed of error
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict 
{
//   NSLog(@"XMLParser: startElement: %@", elementName);
   
   /// TASKPROGRESS 
   if ( [elementName isEqualToString:@"taskprogress"] ) {
      [currentSession setProgress:[attributeDict objectForKey:@"percent"]];
   }
   
   if ( onlyReadProgress == TRUE )
      return;
   

   /// HOST
   if ( [elementName isEqualToString:@"host"] ) {
      
      if (!currentHost) {
         
         // Create new host object in managedObjectContext
         NSManagedObjectContext *context = [currentSession managedObjectContext]; 
         currentHost = [NSEntityDescription insertNewObjectForEntityForName: @"Host" inManagedObjectContext:context];          
         
         // Point back to current session
         [currentHost setSession:currentSession];
      }
      
      return;
   }
   
   /// HOST - STATUS
   if ( [elementName isEqualToString:@"status"] ) 
   {      
      [currentHost setStatus:[[attributeDict objectForKey:@"state"] uppercaseString]];
      [currentHost setStatusReason:[attributeDict objectForKey:@"reason"]];
      
      return;
   }
   
   /// HOST - ADDRESS
   if ( [elementName isEqualToString:@"address"] ) 
   {      
      NSString *addr = [attributeDict objectForKey:@"addr"];            
      NSString *addrtype = [attributeDict objectForKey:@"addrtype"];
      
      if ( [addrtype isEqualToString:@"ipv4"] )
         [currentHost setIpv4Address:addr];
      
      if ( [addrtype isEqualToString:@"mac"] )
         [currentHost setMacAddress:addr];
      
      return;
   }
   
   /// HOST - HOSTNAME
   if ( [elementName isEqualToString:@"hostname"] ) 
   {      
      [currentHost setHostname:[attributeDict objectForKey:@"name"]];
      
      return;
   }   
   
   /// HOST - UPTIME
   if ( [elementName isEqualToString:@"uptime"] ) 
   {
      [currentHost setUptimeSeconds:[attributeDict objectForKey:@"seconds"]];
      [currentHost setUptimeLastBoot:[attributeDict objectForKey:@"lastboot"]];
      
      return;
   }
   

   /// PORT
   if ( [elementName isEqualToString:@"port"] ) {
      
      if (!currentPort) {
         
         // Create new port object in managedObjectContext
         NSManagedObjectContext * context = [currentSession managedObjectContext]; 
         currentPort = [NSEntityDescription insertNewObjectForEntityForName: @"Port" inManagedObjectContext: context];          
         
         // Point back to current session
         [currentPort setHost:currentHost];
//         [currentHost setSession:currentSession];
         [currentPort setNumber:[attributeDict objectForKey:@"portid"]];
         [currentPort setProtocol:[attributeDict objectForKey:@"protocol"]];
      }
      
      return;
   }
   
   /// PORT - STATE
   if ( [elementName isEqualToString:@"state"] ) {

      [currentPort setState:[attributeDict objectForKey:@"state"]];
      [currentPort setStateReason:[attributeDict objectForKey:@"reason"]];
      [currentPort setStateReasonTTL:[attributeDict objectForKey:@"reason_ttl"]];       
      
      return;
   }

   /// PORT - SERVICE
   if ( [elementName isEqualToString:@"service"] ) {
      
      [currentPort setServiceName:[attributeDict objectForKey:@"name"]];
      [currentPort setServiceProduct:[attributeDict objectForKey:@"product"]];
      [currentPort setServiceVersion:[attributeDict objectForKey:@"version"]];
      [currentPort setServiceOsType:[attributeDict objectForKey:@"ostype"]];
      [currentPort setServiceDeviceType:[attributeDict objectForKey:@"devicetype"]];
      [currentPort setServiceMethod:[attributeDict objectForKey:@"method"]];
      [currentPort setServiceConf:[attributeDict objectForKey:@"conf"]];
      
      return;
   }
      
   /// PORT - SCRIPT
   if ( [elementName isEqualToString:@"script"] ) {
      
      [currentPort setScriptID:[attributeDict objectForKey:@"id"]];
      [currentPort setScriptOutput:[attributeDict objectForKey:@"output"]];
      
      return;
   }
   
   if ( [elementName isEqualToString:@"ports"] ) 
   {
      return;
   }
   
   
   /// SERVICE - RUNSTATS
   if ( [elementName isEqualToString:@"runstats"] ) {
      inRunstats = TRUE;
      
      return;
   }   

   if ( [elementName isEqualToString:@"hosts"] ) {
      if (inRunstats == TRUE) {
//         [currentSession setHostsUp:[[attributeDict objectForKey:@"up"] integerValue]];
//         [currentSession setHostsDown:[[attributeDict objectForKey:@"down"] integerValue]];
//         [currentSession setHostsTotal:[[attributeDict objectForKey:@"total"] integerValue]];   
         
         inRunstats = FALSE;          
      }
      
      return;
   }   
   
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{   
   if (!currentStringValue) {      
      
      // currentStringValue is an NSMutableString instance variable      
      currentStringValue = [[NSMutableString alloc] initWithCapacity:50];      
   }
   
   [currentStringValue appendString:string];   
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
//   NSLog(@"XMLParser: endElement: %@", elementName);
   
   if ( [elementName isEqualToString:@"host"] ) {
      currentHost = nil;
      
      return;
   }
   
   if ( [elementName isEqualToString:@"port"] ) {
      currentPort = nil;
      
      return;
   }
   
}














- (void)openXMLFile 
{         
   NSArray *fileTypes = [NSArray arrayWithObject:@"xml"];   
   NSOpenPanel *oPanel = [NSOpenPanel openPanel];   
   NSString *startingDir = [[NSUserDefaults standardUserDefaults] objectForKey:@"StartingDirectory"];
   
   if (!startingDir)      
      startingDir = NSHomeDirectory();
   
   [oPanel setAllowsMultipleSelection:NO];   
   [oPanel beginSheetForDirectory:startingDir file:nil types:fileTypes    
                   modalForWindow:[self window] modalDelegate:self   
                   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)    
                      contextInfo:nil];   
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo 
{   
   NSString *pathToFile = nil;
   
   if (returnCode == NSOKButton) {      
      pathToFile = [[[sheet filenames] objectAtIndex:0] copy];      
   }
   
   if (pathToFile) {
      
      NSString *startingDir = [pathToFile stringByDeletingLastPathComponent];
      [[NSUserDefaults standardUserDefaults] setObject:startingDir forKey:@"StartingDirectory"];
      [self parseXMLFile:pathToFile];
   }
}

@end