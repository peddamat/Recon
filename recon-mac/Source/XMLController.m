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
#import "OsClass.h"
#import "OsMatch.h"
#import "Port_Script.h"

@interface XMLController ()

   @property (readwrite, retain) NSXMLParser *addressParser;
   @property (readwrite, retain) NSMutableString *currentStringValue;

// Temporary MOC
   @property (readwrite,assign) NSManagedObjectContext *temporaryContext;

// Managed objects that we populate
   @property (readwrite, retain) Session *currentSession;
   @property (readwrite, retain) Host *currentHost;
   @property (readwrite, retain) Port *currentPort;
   @property (readwrite, retain) OsClass *currentOsClass;
   @property (readwrite, retain) OsMatch *currentOsMatch;   

// State-machine helper flags
   @property (readwrite, assign) BOOL inRunstats;   

@end


@implementation XMLController

@synthesize addressParser;
@synthesize currentStringValue;
@synthesize temporaryContext;
@synthesize currentSession;
@synthesize currentHost;
@synthesize currentPort;
@synthesize currentOsClass;
@synthesize currentOsMatch;
@synthesize inRunstats;

- (id)init
{
   if (self = [super init])
      self.inRunstats = FALSE;
   
   return self;
}

- (void)dealloc
{
   [addressParser release];
   [currentStringValue release];
   [temporaryContext release];
   [currentSession release];
   [currentHost release];
   [currentPort release];
   [currentOsClass release];
   [currentOsMatch release];
   [super dealloc];
}

// -------------------------------------------------------------------------------
//	parseXMLFile: Parse Nmap output into a temporary managed object context.  If
//               no errors occur, merge new context with persistent store.
// -------------------------------------------------------------------------------
- (void)parseXMLFile:(NSString *)pathToFile inSession:(Session *)session
{     
   // Load the Nmap xml output
   NSURL *xmlURL = [NSURL fileURLWithPath:pathToFile];
   
   // Allocate an event-based parser
   self.addressParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
   [addressParser setDelegate:self];
   [addressParser setShouldResolveExternalEntities:YES];
   
   // Create new scratchpad context
   self.temporaryContext = [[NSManagedObjectContext alloc] init];   
   [temporaryContext setUndoManager:nil];      
   [temporaryContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];   
   
   // Grab the main Persistent Store Coordinator
   NSPersistentStoreCoordinator *coordinator = [[session managedObjectContext] persistentStoreCoordinator];   
   [temporaryContext setPersistentStoreCoordinator:coordinator];   
   
   // Save the main Managed Object Context to ensure the new Session has been persisted
   NSError *error = nil;     
   [[session managedObjectContext] save:&error]; 
   
   // The scratch pad MOC needs a reference to the new Session from the main MOC
   NSManagedObjectID *objectID = [session objectID];
   self.currentSession = (Session *)[temporaryContext objectWithID:objectID];
      
   // Cache the Host entity to optimize for looong scan outputs
   hostEntity = [[NSEntityDescription entityForName:@"Host"                 
                            inManagedObjectContext:temporaryContext] retain];
   
   BOOL success = [addressParser parse]; 
   
   // Only save changes if parser is a success
   if (success == YES) 
   {
      [temporaryContext save:&error];
      [[session managedObjectContext] refreshObject:session mergeChanges:NO];
      [[session managedObjectContext] save:&error];
   }
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
    attributes:(NSDictionary *)attributeDict 
{      
//   NSLog(@"P: %@", elementName);
   
   /// HOST
   if ( [elementName isEqualToString:@"host"] ) {
      
      if (!currentHost) {
         
         // Create new host object in managedObjectContext 
         self.currentHost = [[NSManagedObject alloc] initWithEntity:hostEntity insertIntoManagedObjectContext:temporaryContext];         
         
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
         self.currentPort = [NSEntityDescription insertNewObjectForEntityForName: @"Port" inManagedObjectContext: temporaryContext];          
         
         // Point back to current host
         [currentPort setHost:currentHost];
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
       
      Port_Script *script = [NSEntityDescription insertNewObjectForEntityForName: @"Port_Script" inManagedObjectContext: temporaryContext];                   
      
      [script setId:[attributeDict objectForKey:@"id"]];
      NSString *output = [attributeDict objectForKey:@"output"];
      output = [output stringByReplacingOccurrencesOfString:@"\n" withString:@": "];
      [script setOutput:output];
      [script setPort:currentPort];
      
      script = nil;
      
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
      if (inRunstats == TRUE) 
      {
         [currentSession setHostsUp:[NSNumber numberWithInt:[[attributeDict objectForKey:@"up"] integerValue]]];
         [currentSession setHostsDown:[NSNumber numberWithInt:[[attributeDict objectForKey:@"down"] integerValue]]];
         [currentSession setHostsTotal:[NSNumber numberWithInt:[[attributeDict objectForKey:@"total"] integerValue]]];            
         self.inRunstats = FALSE;          
      }
      
      return;
   }   
   
   
   /// HOST - OSCLASS
   if ( [elementName isEqualToString:@"osclass"] ) {

      if (!currentOsClass) {
         
         // Create new port object in managedObjectContext
         self.currentOsClass = [NSEntityDescription insertNewObjectForEntityForName: @"OsClass" inManagedObjectContext: temporaryContext];                   

         // Point back to current session
         [currentOsClass setHost:currentHost];
      }
      
      [currentOsClass setType:[attributeDict objectForKey:@"type"]];
      [currentOsClass setVendor:[attributeDict objectForKey:@"vendor"]];
      [currentOsClass setFamily:[attributeDict objectForKey:@"osfamily"]];               
      [currentOsClass setGen:[attributeDict objectForKey:@"osgen"]];                     
      [currentOsClass setAccuracy:[attributeDict objectForKey:@"accuracy"]];  
      
      return;
   }
   
   /// HOST - OSMATCH   
   if ( [elementName isEqualToString:@"osmatch"] ) {

      if (!currentOsMatch) {
         
         // Create new port object in managedObjectContext
         self.currentOsMatch = [NSEntityDescription insertNewObjectForEntityForName: @"OsMatch" inManagedObjectContext: temporaryContext];                   
         
         // Point back to current session
         [currentOsMatch setHost:currentHost];
      }
      
      [currentOsMatch setName:[attributeDict objectForKey:@"name"]];      
      [currentOsMatch setAccuracy:[attributeDict objectForKey:@"accuracy"]];    
      [currentOsMatch setLine:[attributeDict objectForKey:@"line"]];    
      
      return;
   }
   
   /// HOST - IPIDSEQUENCE   
   if ( [elementName isEqualToString:@"ipidsequence"] ) {
      
      [currentHost setIpIdSequenceClass:[attributeDict objectForKey:@"class"]];      
      
      NSString *valuesString = [attributeDict objectForKey:@"values"];
      NSArray *valuesArray = [valuesString componentsSeparatedByString:@","];
      
      for (NSString *object in valuesArray)
      {
         // Create new port object in managedObjectContext
         IpIdSeqValue *value = [NSEntityDescription insertNewObjectForEntityForName: @"IpIdSeqValue" inManagedObjectContext: temporaryContext];                   
         [value setHost:currentHost];
         [value setValue:object];
      }      
      
      return;
   }   
   
   /// HOST - TCPSEQUENCE   
   if ( [elementName isEqualToString:@"tcpsequence"] ) {
            
      [currentHost setTcpSequenceIndex:[attributeDict objectForKey:@"index"]];      
      [currentHost setTcpSequenceDifficulty:[attributeDict objectForKey:@"difficulty"]];    

      NSString *valuesString = [attributeDict objectForKey:@"values"];
      NSArray *valuesArray = [valuesString componentsSeparatedByString:@","];

      for (NSString *object in valuesArray)
      {
         // Create new port object in managedObjectContext
         TcpSeqValue *value = [NSEntityDescription insertNewObjectForEntityForName: @"TcpSeqValue" inManagedObjectContext: temporaryContext];                   
         [value setHost:currentHost];
         [value setValue:object];
      }

      return;
   }   
   
   /// HOST - TCPTSSEQUENCE   
   if ( [elementName isEqualToString:@"tcptssequence"] ) {
      
      [currentHost setTcpTsSequenceClass:[attributeDict objectForKey:@"class"]]; 
      
      NSString *valuesString = [attributeDict objectForKey:@"values"];
      NSArray *valuesArray = [valuesString componentsSeparatedByString:@","];
      
      for (NSString *object in valuesArray)
      {
         // Create new port object in managedObjectContext
         TcpTsSeqValue *value = [NSEntityDescription insertNewObjectForEntityForName: @"TcpTsSeqValue" inManagedObjectContext: temporaryContext];                   
         [value setHost:currentHost];
         [value setValue:object];
      }
      
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
//   //ANSLog(@"XMLParser: endElement: %@", elementName);
   
   if ( [elementName isEqualToString:@"host"] ) {
      [self.currentHost release];
      self.currentHost = nil;
      
      return;
   }
   
   if ( [elementName isEqualToString:@"port"] ) {
      self.currentPort = nil;
      
      return;
   }
   
   if ( [elementName isEqualToString:@"osclass"] ) {
      self.currentOsClass = nil;
      
      return;
   }
   
   if ( [elementName isEqualToString:@"osmatch"] ) {
      self.currentOsMatch = nil;
      
      return;
   }
}

@end
