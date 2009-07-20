//
//  XMLController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 6/30/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "XMLController.h"
#import "Profile.h"
#import "Host.h"
#import "Port.h"
#import "Session.h"
#import "OperatingSystem.h"

@interface XMLController ()

   @property (readwrite, retain) NSXMLParser *addressParser;
   @property (readwrite, retain) NSMutableString *currentStringValue;

// Managed objects that we populate
   @property (readwrite, retain) Session *currentSession;
   @property (readwrite, retain) Host *currentHost;
   @property (readwrite, retain) Port *currentPort;
   @property (readwrite, retain) OperatingSystem *currentOperatingSystem;   

// State-machine helper flag
   @property (readwrite, assign) BOOL inRunstats;   
   @property (readwrite, assign) BOOL inOsclass;   
   @property (readwrite, assign) BOOL inOsmatch;   

   @property (readwrite, assign) BOOL onlyReadProgress;

@end


@implementation XMLController

@synthesize addressParser;
@synthesize currentStringValue;
@synthesize currentSession;
@synthesize currentHost;
@synthesize currentPort;
@synthesize currentOperatingSystem;
@synthesize inRunstats;
@synthesize inOsclass;
@synthesize inOsmatch;
@synthesize onlyReadProgress;

- (void)dealloc
{
   [addressParser release];
   [currentStringValue release];
   [currentSession release];
   [currentHost release];
   [currentPort release];
   [currentOperatingSystem release];
   [super dealloc];
}

// -------------------------------------------------------------------------------
//	parseXMLFile: 
// -------------------------------------------------------------------------------
- (void)parseXMLFile:(NSString *)pathToFile inSession:(Session *)session onlyReadProgress:(BOOL)oReadProgress
{   
   BOOL success;
   NSURL *xmlURL = [NSURL fileURLWithPath:pathToFile];
   
   self.inRunstats = FALSE;
   self.onlyReadProgress = oReadProgress;
   
   // Save current session
   self.currentSession = session;
      
   self.addressParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
   [addressParser setDelegate:self];
   [addressParser setShouldResolveExternalEntities:YES];
   success = [addressParser parse]; // return value not used
   // if not successful, delegate is informed of error
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
    attributes:(NSDictionary *)attributeDict 
{
   
   /// TASKPROGRESS 
   if ( [elementName isEqualToString:@"taskprogress"] ) {
      NSString *progress = [attributeDict objectForKey:@"percent"];
      [currentSession setProgress:[NSNumber numberWithFloat:[progress floatValue]]];
      [currentSession setStatus:[attributeDict objectForKey:@"task"]];
   }
   
   if ( onlyReadProgress == TRUE )
      return;
   

   /// HOST
   if ( [elementName isEqualToString:@"host"] ) {
      
      if (!currentHost) {
         
         // Create new host object in managedObjectContext
         NSManagedObjectContext *context = [currentSession managedObjectContext]; 
         self.currentHost = [NSEntityDescription insertNewObjectForEntityForName: @"Host" inManagedObjectContext:context];          
         
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
   
   /// HOST - DISTANCE
   if ( [elementName isEqualToString:@"distance"] ) 
   {
      [currentHost setDistance:[attributeDict objectForKey:@"value"]];
      
      return;
   }
   
   
   /// PORT
   if ( [elementName isEqualToString:@"port"] ) {
      
      if (!currentPort) {
         
         // Create new port object in managedObjectContext
         NSManagedObjectContext * context = [currentSession managedObjectContext]; 
         self.currentPort = [NSEntityDescription insertNewObjectForEntityForName: @"Port" inManagedObjectContext: context];          
         
         // Point back to current session
         [currentPort setHost:currentHost];
//         [currentHost setSession:currentSession];
         [currentPort setNumber:[NSNumber numberWithInt:[[attributeDict objectForKey:@"portid"] intValue]]];
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
      self.inRunstats = TRUE;
      
      return;
   }   

   if ( [elementName isEqualToString:@"hosts"] ) {
      if (inRunstats == TRUE) {
//         [currentSession setHostsUp:[[attributeDict objectForKey:@"up"] integerValue]];
//         [currentSession setHostsDown:[[attributeDict objectForKey:@"down"] integerValue]];
//         [currentSession setHostsTotal:[[attributeDict objectForKey:@"total"] integerValue]];   
         
         self.inRunstats = FALSE;          
      }
      
      return;
   }   
   
   
   /// HOST - OSCLASS
   if ( [elementName isEqualToString:@"osclass"] ) {

      if (!currentOperatingSystem) {
         
         // Create new port object in managedObjectContext
         NSManagedObjectContext * context = [currentSession managedObjectContext]; 
         self.currentOperatingSystem = [NSEntityDescription insertNewObjectForEntityForName: @"OperatingSystem" inManagedObjectContext: context];                   

         // Point back to current session
         [currentOperatingSystem setHost:currentHost];
      }
      
      inOsclass = TRUE;
      
      [currentOperatingSystem setType:[attributeDict objectForKey:@"type"]];
      [currentOperatingSystem setVendor:[attributeDict objectForKey:@"vendor"]];
      [currentOperatingSystem setFamily:[attributeDict objectForKey:@"osfamily"]];               
      [currentOperatingSystem setGen:[attributeDict objectForKey:@"osgen"]];                     
      [currentOperatingSystem setAccuracy:[attributeDict objectForKey:@"accuracy"]];  

      
      return;
   }
   
   if ( [elementName isEqualToString:@"osmatch"] ) {

      if (!currentOperatingSystem) {
         
         // Create new port object in managedObjectContext
         NSManagedObjectContext * context = [currentSession managedObjectContext]; 
         self.currentOperatingSystem = [NSEntityDescription insertNewObjectForEntityForName: @"OperatingSystem" inManagedObjectContext: context];                   
         
         // Point back to current session
         [currentOperatingSystem setHost:currentHost];
      }
      
      inOsmatch = TRUE;
      
      [currentOperatingSystem setName:[attributeDict objectForKey:@"name"]];      
      
      return;
   }
   
}

// -------------------------------------------------------------------------------
//	parser:foundCharacters:
// -------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{   
   if (!currentStringValue) {      
      
      // currentStringValue is an NSMutableString instance variable      
      currentStringValue = [[NSMutableString alloc] initWithCapacity:50];      
   }
   
   [currentStringValue appendString:string];   
}

// -------------------------------------------------------------------------------
//	parser:didEndElement:namespaceURI:
// -------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
//   NSLog(@"XMLParser: endElement: %@", elementName);
   
   if ( [elementName isEqualToString:@"host"] ) {
      self.currentHost = nil;
      
      return;
   }
   
   if ( [elementName isEqualToString:@"port"] ) {
      self.currentPort = nil;
      
      return;
   }
   
   if ( [elementName isEqualToString:@"osclass"] ) {
      inOsclass = FALSE;
      
      if (inOsmatch == FALSE)
         self.currentOperatingSystem = nil;
      
      return;
   }
   
   if ( [elementName isEqualToString:@"osmatch"] ) {
      inOsmatch = FALSE;
      
      if (inOsclass == FALSE)
         self.currentOperatingSystem = nil;
      
   }
}

@end
