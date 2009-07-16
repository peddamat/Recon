//
//  ArgumentListGenerator.m
//  recon
//
//  Created by Sumanth Peddamatham on 6/30/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "ArgumentListGenerator.h"


@implementation ArgumentListGenerator

+ (NSArray *) convertProfileToArgs:(Profile *)profile 
                        withTarget:(NSString *)target 
                     withOutputFile:(NSString*)nmapOutput
{
   
   NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Profile" 
                                                        inManagedObjectContext:[profile managedObjectContext]];
   // Retrieve all attributes for Profile entity
   NSDictionary *profileAttributes = [entityDescription attributesByName];
   // Separate keys from values (attributes are keys)
   NSArray *profileKeys = [profileAttributes allKeys];
   // Retrieve attribute values with key list
   profileAttributes = [profile dictionaryWithValuesForKeys:profileKeys];
   
   // -------------------------------------------------------------------------------
   //	The next two dictionaries have the keys and values reversed.  I'll fix this later
   // -------------------------------------------------------------------------------
   
   NSDictionary *nmapArgsString = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"ackPing",@"-PA",
                                   @"debuggingLevel",@"-d",  
                                   @"excludeFile",@"--excludefile",
                                   @"excludeHosts",@"--exclude",
                                   @"extraOptions",@"",                                   
                                   @"ftpBounce",@"-b",                                            
                                   @"idleScan",@"-sI",
                                   @"ipprotoProbe",@"-PO",                                            
                                   @"portsToScan",@"-p",
                                   @"scanRandom",@"-iR",                                            
                                   @"scriptArgs",@"--script-args",
                                   @"scriptsToRun",@"--script",   
                                   @"setIPv4TTL",@"--ttl",
                                   @"setNetworkInterface",@"-e",
                                   @"setSourceIP",@"-S",
                                   @"setSourcePort",@"--source-port",                                    
                                   @"synPing",@"-PS",                                            
                                   @"targetList",@"-ILA",
                                   @"udpProbe",@"-PU",  
                                   @"useDecoys",@"-D",
                                   @"verbosity",@"-v",                                            
                                   nil];
      
   NSDictionary *nmapArgsBool = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"defaultPing",@"-PB",                                            
                                   @"disableRandom",@"-r",                                            
                                   @"disableReverseDNS",@"-n",
                                   @"dontPing",@"-PN",
                                   @"enableAggressive",@"-A",                                            
                                   @"fastScan",@"-F",
                                   @"fragmentIP",@"-f",                                            
                                   @"icmpNetmask",@"-PM",
                                   @"icmpPing",@"-PE",
                                   @"icmpTimeStamp",@"-PP",                                                                                        
                                   @"initialProbeTimeout",@"--initial-rtt-timeout ",                                            
                                   @"ipv6Support",@"-6",                                            
                                   @"maxHostsParallel",@"--max-hostgroup",
                                   @"maxOutstandingProbes",@"--max-parallelism",
                                   @"maxProbeTimeout",@"--max-rtt-timeout",
                                   @"maxRetries",@"--max-retries",
                                   @"maxScanDelay",@"--max-scan-delay",
                                   @"maxTimeToScan",@"--host-timeout",
                                   @"minDelayBetweenProbes",@"--scan-delay",
                                   @"minDelayBetweenProbes",@"",
                                   @"minHostsParallel",@"--min-hostgroup",
                                   @"minOutstandingProbes",@"--min-parallelism",
                                   @"minProbeTimeout",@"--min-rtt-timeout",                                            
                                   @"osDetection",@"-O",                                            
                                   @"packetTrace",@"--packet-trace",
                                   @"scriptScan",@"-sC",                                         
                                   @"traceRoute",@"--traceroute",
                                   @"traceScript",@"--script-trace",                                       
                                   @"versionDetection",@"-sV",
                                   nil];
   
   // FUUUUUCK!
   //  I entered the key/value pairs in the wrong order.  :(  Swapping manually...
   NSArray *keys = [nmapArgsBool allKeys];
   NSArray *values = [nmapArgsBool allValues];   
   nmapArgsBool = [NSDictionary dictionaryWithObjects:keys forKeys:values];
   keys = [nmapArgsString allKeys];
   values = [nmapArgsString allValues];   
   nmapArgsString = [NSDictionary dictionaryWithObjects:keys forKeys:values];   
   
   id dictKey, dictValue;   
   NSNumber *numYes = [NSNumber numberWithInt:0];
   
   // Array to store generated argument list
   NSMutableArray *nmapArgs = [[NSMutableArray alloc] init];
   
   // First iterate through boolean arguments
   NSEnumerator *e = [nmapArgsBool keyEnumerator];
   
   while ( dictKey = [e nextObject] )
   {
      if([[profileAttributes valueForKey: dictKey] compare:numYes])
      {
         dictValue = [nmapArgsBool valueForKey:dictKey];
         [nmapArgs addObject:dictValue];
      }      
   }
   
   // Next, iterate through arguments with strings
   e = [nmapArgsString keyEnumerator];
   
   while ( dictKey = [e nextObject] )
   {
      if([[profileAttributes valueForKey: dictKey] compare:numYes])
      {
         // First add argument flag
         dictValue = [nmapArgsString valueForKey:dictKey];
         [nmapArgs addObject:dictValue];

         // Next, add user string from profile
         dictValue = [profile valueForKey:[dictKey stringByAppendingString:@"String"]];
         [nmapArgs addObject:dictValue];   
      }      
   }   
      
   // -------------------------------------------------------------------------------
   //	These are hard-coded dictionaries for the popups.  HACKY CODE!  
   // -------------------------------------------------------------------------------
   
   NSDictionary *nmapArgsTcpString = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"",@"0",                                      
                                      @"-sA",@"1",
                                      @"-sF",@"2",
                                      @"-sM",@"3",
                                      @"-sN",@"4",
                                      @"-sS",@"5",
                                      @"-sT",@"6",
                                      @"-sW",@"7",
                                      @"-sX",@"8",
                                      nil];
   
   NSDictionary *nmapArgsNonTcpString = [NSDictionary dictionaryWithObjectsAndKeys:   
                                         @"",@"0",
                                         @"-sU",@"1",
                                         @"-sO",@"2",
                                         @"-sL",@"3",
                                         @"-sP",@"4",
                                         nil];
   
   NSDictionary *nmapArgsTimingString = [NSDictionary dictionaryWithObjectsAndKeys:
                                         @"",@"0",
                                         @"-T0",@"1",
                                         @"-T1",@"2",
                                         @"-T2",@"3",
                                         @"-T3",@"4",
                                         @"-T4",@"5",
                                         @"-T5",@"6",
                                         nil];
   
//   dictValue = [profile valueForKey:@"tcpScanTag"];
//   if (dictValue == nil) dictValue = [NSNumber numberWithInt:0];
//   [nmapArgs addObject:[nmapArgsTcpString valueForKey:[dictValue stringValue]]];
//
//   dictValue = [profile valueForKey:@"nonTcpScanTag"];
//   if (dictValue == nil) dictValue = [NSNumber numberWithInt:0];
//   [nmapArgs addObject:[nmapArgsNonTcpString valueForKey:[dictValue stringValue]]];
//
//   dictValue = [profile valueForKey:@"timingTemplateTag"];
//   if (dictValue == nil) dictValue = [NSNumber numberWithInt:0];
//   [nmapArgs addObject:[nmapArgsTimingString valueForKey:[dictValue stringValue]]];

   // -------------------------------------------------------------------------------
   //	/END hacky code...
   // -------------------------------------------------------------------------------
      
   // Finally add XML output location and target(s)
//   [nmapArgs addObject:@"--stats-every"];
//   [nmapArgs addObject:@"1"];   
   [nmapArgs addObject:@"-oX"];
   [nmapArgs addObject:nmapOutput];
   [nmapArgs addObject:target];
   
   return nmapArgs;
}

@end
