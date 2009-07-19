//
//  ArgumentListGenerator.m
//  Recon
//
//  Created by Sumanth Peddamatham on 6/30/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "ArgumentListGenerator.h"


@implementation ArgumentListGenerator

@synthesize nmapArgsBool;
@synthesize nmapArgsString;

@synthesize nmapArgsBoolReverse;
@synthesize nmapArgsStringReverse;

@synthesize nmapArgsTcpString;
@synthesize nmapArgsNonTcpString;
@synthesize nmapArgsTimingString;


- (id)init
{
   if (self = [super init])
   {
      NSArray *allKeys;
      NSArray *allValues;
      
      nmapArgsString = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"-PA",@"ackPing",
                        @"-d",@"debuggingLevel",
                        @"--excludefile",@"excludeFile",
                        @"--exclude",@"excludeHosts",
                        @"",@"extraOptions",
                        @"-b",@"ftpBounce",                                     
                        @"--host-timeout",@"hostTimeout",
                        @"-sI",@"idleScan",
                        @"-PO",@"ipprotoProbe",
                        @"--max-rtt-timeout",@"maxRttTimeout",
                        @"--min-rtt-timeout",@"minRttTimeout",
                        @"--initial-rtt-timeout",@"initialRttTimeout",
                        @"--max-hostgroup",@"maxHostgroup",
                        @"--min-hostgroup",@"minHostgroup",
                        @"--max-parallelism",@"maxParallelism",
                        @"--min-parallelism",@"minParallelism",
                        @"--max-scan-delay",@"maxScanDelay",
                        @"--scan-delay",@"scanDelay",
                        @"-p",@"portsToScan",
                        @"-iR",@"scanRandom",
                        @"--script-args",@"scriptArgs",
                        @"--script",@"scriptsToRun",
                        @"--ttl",@"setIPv4TTL",
                        @"-e",@"setNetworkInterface",
                        @"-S",@"setSourceIP",
                        @"--source-port",@"setSourcePort",
                        @"-PS",@"synPing",
                        @"-ILA",@"targetList",
                        @"-PU",@"udpProbe",
                        @"-D",@"useDecoys",
                        @"-v",@"verbosity",
                        nil];
            
      allKeys = [nmapArgsString allKeys];
      allValues = [nmapArgsString allValues];      
      nmapArgsStringReverse = [NSDictionary dictionaryWithObjects:allKeys forKeys:allValues];      
      
      nmapArgsBool = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"-PB",@"defaultPing",
                        @"-r",@"disableRandom",
                        @"-n",@"disableReverseDNS",
                        @"-PN",@"dontPing",
                        @"-A",@"enableAggressive",
                        @"-F",@"fastScan",
                        @"-f",@"fragmentIP",
                        @"-PM",@"icmpNetmask",
                        @"-PE",@"icmpPing",
                        @"-PP",@"icmpTimeStamp",
                        @"--initial-rtt-timeout",@"initialProbeTimeout",
                        @"-6",@"ipv6Support",
                        @"--max-hostgroup",@"maxHostsParallel",
                        @"--max-parallelism",@"maxOutstandingProbes",
                        @"--max-rtt-timeout",@"maxProbeTimeout",
                        @"--max-retries",@"maxRetries",
                        @"--max-scan-delay",@"maxScanDelay",
                        @"--host-timeout",@"maxTimeToScan",
                        @"--scan-delay",@"minDelayBetweenProbes",
                        @"--min-hostgroup",@"minHostsParallel",
                        @"--min-parallelism",@"minOutstandingProbes",
                        @"--min-rtt-timeout",@"minProbeTimeout",
                        @"-O",@"osDetection",
                        @"--packet-trace",@"packetTrace",
                        @"-sC",@"scriptScan",
                        @"--traceroute",@"traceRoute",
                        @"--script-trace",@"traceScript",
                        @"-sV",@"versionDetection",
                        nil];
      
      allKeys = [nmapArgsBool allKeys];
      allValues = [nmapArgsBool allValues];      
      nmapArgsBoolReverse = [NSDictionary dictionaryWithObjects:allKeys forKeys:allValues];
      
      nmapArgsTcpString = [NSDictionary dictionaryWithObjectsAndKeys:
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
      
      nmapArgsNonTcpString = [NSDictionary dictionaryWithObjectsAndKeys:   
                        @"",@"0",
                        @"-sU",@"1",
                        @"-sO",@"2",
                        @"-sL",@"3",
                        @"-sP",@"4",
                        nil];
      
      nmapArgsTimingString = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"-T0",@"0",
                        @"-T1",@"1",
                        @"-T2",@"2",
                        @"-T3",@"3",
                        @"-T4",@"4",
                        @"-T5",@"5",
                        nil];
   }
   
   return self;
}

- (void)dealloc
{
   [nmapArgsBool release];
   [nmapArgsString release];
   [nmapArgsBoolReverse release];
   [nmapArgsStringReverse release];
   [super dealloc];
}


// -------------------------------------------------------------------------------
//	convertProfileToArgs
// -------------------------------------------------------------------------------
- (NSArray *) convertProfileToArgs:(Profile *)profile 
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
      
   id dictValue;   

   NSNumber *numYes = [NSNumber numberWithInt:0];
   
   // Array to store generated argument list
   NSMutableArray *nmapArgs = [[NSMutableArray alloc] init];
  
   // First iterate through boolean arguments
   for (NSString *dictKey in nmapArgsBool)
   {
      if([[profileAttributes valueForKey:dictKey] compare:numYes])
      {
         dictValue = [nmapArgsBool valueForKey:dictKey];
         [nmapArgs addObject:dictValue];
      }      
   }
   
   // Next, iterate through arguments with string argument
   for (NSString *dictKey in nmapArgsString)
   {
      if([[profileAttributes valueForKey:dictKey] compare:numYes])
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
   
   
   dictValue = [profile valueForKey:@"tcpScanTag"];
   if (dictValue != nil)
      [nmapArgs addObject:[nmapArgsTcpString valueForKey:[dictValue stringValue]]];

   dictValue = [profile valueForKey:@"nonTcpScanTag"];
   if (dictValue != nil)
      [nmapArgs addObject:[nmapArgsNonTcpString valueForKey:[dictValue stringValue]]];

   dictValue = [profile valueForKey:@"timingTemplateTag"];
   if (dictValue != nil)
      [nmapArgs addObject:[nmapArgsTimingString valueForKey:[dictValue stringValue]]];
   
   // -------------------------------------------------------------------------------
   //	/END hacky code...
   // -------------------------------------------------------------------------------
   
   // Finally add XML output location and target(s)
   [nmapArgs addObject:@"-stats-every"];
   [nmapArgs addObject:@"50"];   
   [nmapArgs addObject:@"-oX"];
   [nmapArgs addObject:nmapOutput];
   [nmapArgs addObject:target];
   
   return nmapArgs;
}

// -------------------------------------------------------------------------------
//	areFlagsValid
// -------------------------------------------------------------------------------
- (BOOL)areFlagsValid:(NSArray *)argArray
{
   BOOL ok = TRUE;   
   
   // First iterate through boolean arguments
   for (NSString *argString in argArray)
   {            
      if (([nmapArgsBoolReverse objectForKey:argString] == nil) &&
          ([nmapArgsStringReverse objectForKey:argString] == nil) )
      {
         ok = FALSE;
      }         
   }
   
   return ok;
}

// -------------------------------------------------------------------------------
//	populateProfile
// -------------------------------------------------------------------------------
- (void)populateProfile:(Profile *)profile withArgString:(NSArray *)argArray
{

   // First iterate through boolean arguments
   for (NSString *argString in argArray)
   {
      NSString *v = [nmapArgsBoolReverse valueForKey:argString];
      if (v != nil) {
         [profile setValue:[NSNumber numberWithInt:1] forKey:v];
         continue;
      }
      
      v = [nmapArgsStringReverse valueForKey:argString];
      if (v != nil)
         [profile setValue:[NSNumber numberWithInt:1] forKey:v];
   }
   
}
   
@end
