//
//  Profile.h
//  recon
//
//  Created by Sumanth Peddamatham on 8/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Session;

@interface Profile :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * scanDelayString;
@property (nonatomic, retain) NSNumber * icmpTimeStamp;
@property (nonatomic, retain) NSNumber * debuggingLevel;
@property (nonatomic, retain) NSString * maxParallelismString;
@property (nonatomic, retain) NSNumber * minParallelism;
@property (nonatomic, retain) NSString * setSourcePortString;
@property (nonatomic, retain) NSString * scanRandomString;
@property (nonatomic, retain) NSNumber * scriptArgs;
@property (nonatomic, retain) NSNumber * dontPing;
@property (nonatomic, retain) NSNumber * minHostgroup;
@property (nonatomic, retain) NSString * ftpBounceString;
@property (nonatomic, retain) NSNumber * maxTimeToScan;
@property (nonatomic, retain) NSNumber * scriptScan;
@property (nonatomic, retain) NSNumber * maxProbeTimeout;
@property (nonatomic, retain) NSNumber * initialRttTimeout;
@property (nonatomic, retain) NSString * synPingString;
@property (nonatomic, retain) NSNumber * maxOutstandingProbes;
@property (nonatomic, retain) NSString * targetListString;
@property (nonatomic, retain) NSNumber * idleScan;
@property (nonatomic, retain) NSNumber * scanRandom;
@property (nonatomic, retain) NSNumber * excludeFile;
@property (nonatomic, retain) NSNumber * enableAggressive;
@property (nonatomic, retain) NSString * initialRttTimeoutString;
@property (nonatomic, retain) NSNumber * scriptsToRun;
@property (nonatomic, retain) NSNumber * excludeHosts;
@property (nonatomic, retain) NSString * sessionTarget;
@property (nonatomic, retain) NSNumber * minHostsParallel;
@property (nonatomic, retain) NSString * minHostsParallelString;
@property (nonatomic, retain) NSString * maxTimeToScanString;
@property (nonatomic, retain) NSString * debuggingLevelString;
@property (nonatomic, retain) NSNumber * ipv6Support;
@property (nonatomic, retain) NSNumber * synPing;
@property (nonatomic, retain) NSNumber * maxHostgroup;
@property (nonatomic, retain) NSNumber * versionDetection;
@property (nonatomic, retain) NSNumber * verbosity;
@property (nonatomic, retain) NSString * minOutstandingProbesString;
@property (nonatomic, retain) NSNumber * hostTimeout;
@property (nonatomic, retain) NSNumber * initialProbeTimeout;
@property (nonatomic, retain) NSString * useDecoysString;
@property (nonatomic, retain) NSNumber * minDelayBetweenProbes;
@property (nonatomic, retain) NSString * setIPv4TTLString;
@property (nonatomic, retain) NSNumber * traceRoute;
@property (nonatomic, retain) NSString * idleScanString;
@property (nonatomic, retain) NSNumber * udpProbe;
@property (nonatomic, retain) NSString * minProbeTimeoutString;
@property (nonatomic, retain) NSString * maxHostsParallelString;
@property (nonatomic, retain) NSString * setSourceIPString;
@property (nonatomic, retain) NSNumber * portsToScan;
@property (nonatomic, retain) NSNumber * osDetection;
@property (nonatomic, retain) NSNumber * fragmentIP;
@property (nonatomic, retain) NSNumber * maxRetries;
@property (nonatomic, retain) NSString * initialProbeTimeoutString;
@property (nonatomic, retain) NSNumber * maxScanDelay;
@property (nonatomic, retain) NSString * excludeHostsString;
@property (nonatomic, retain) NSString * minHostgroupString;
@property (nonatomic, retain) NSNumber * maxParallelism;
@property (nonatomic, retain) NSString * maxScanDelayString;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * traceScript;
@property (nonatomic, retain) NSString * maxRttTimeoutString;
@property (nonatomic, retain) NSString * portsToScanString;
@property (nonatomic, retain) NSString * minParallelismString;
@property (nonatomic, retain) NSNumber * scanDelay;
@property (nonatomic, retain) NSNumber * minOutstandingProbes;
@property (nonatomic, retain) NSString * minDelayBetweenProbesString;
@property (nonatomic, retain) NSNumber * isEnabled;
@property (nonatomic, retain) NSString * ackPingString;
@property (nonatomic, retain) NSNumber * fastScan;
@property (nonatomic, retain) NSNumber * setSourcePort;
@property (nonatomic, retain) NSString * setNetworkInterfaceString;
@property (nonatomic, retain) NSNumber * ipprotoProbe;
@property (nonatomic, retain) NSString * maxRetriesString;
@property (nonatomic, retain) NSNumber * maxHostsParallel;
@property (nonatomic, retain) NSNumber * maxRttTimeout;
@property (nonatomic, retain) NSString * hostTimeoutString;
@property (nonatomic, retain) NSString * scriptsToRunString;
@property (nonatomic, retain) NSString * scriptArgsString;
@property (nonatomic, retain) NSString * maxOutstandingProbesString;
@property (nonatomic, retain) NSNumber * minProbeTimeout;
@property (nonatomic, retain) NSString * excludeFileString;
@property (nonatomic, retain) NSNumber * tcpScanTag;
@property (nonatomic, retain) NSNumber * timingTemplateTag;
@property (nonatomic, retain) NSNumber * minRttTimeout;
@property (nonatomic, retain) NSNumber * icmpNetmask;
@property (nonatomic, retain) NSNumber * packetTrace;
@property (nonatomic, retain) NSString * maxHostgroupString;
@property (nonatomic, retain) NSNumber * targetList;
@property (nonatomic, retain) NSString * minRttTimeoutString;
@property (nonatomic, retain) NSNumber * icmpPing;
@property (nonatomic, retain) NSNumber * ftpBounce;
@property (nonatomic, retain) NSString * udpProbeString;
@property (nonatomic, retain) NSNumber * nonTcpScanTag;
@property (nonatomic, retain) NSNumber * setIPv4TTL;
@property (nonatomic, retain) NSNumber * defaultPing;
@property (nonatomic, retain) NSString * ipprotoProbeString;
@property (nonatomic, retain) NSNumber * setSourceIP;
@property (nonatomic, retain) NSString * verbosityString;
@property (nonatomic, retain) NSNumber * ackPing;
@property (nonatomic, retain) NSString * extraOptionsString;
@property (nonatomic, retain) NSString * maxProbeTimeoutString;
@property (nonatomic, retain) NSNumber * disableReverseDNS;
@property (nonatomic, retain) NSNumber * useDecoys;
@property (nonatomic, retain) NSNumber * disableRandom;
@property (nonatomic, retain) NSNumber * extraOptions;
@property (nonatomic, retain) NSNumber * setNetworkInterface;
@property (nonatomic, retain) NSSet* sessions;
@property (nonatomic, retain) NSSet* children;
@property (nonatomic, retain) Profile * parent;

@end


@interface Profile (CoreDataGeneratedAccessors)
- (void)addSessionsObject:(Session *)value;
- (void)removeSessionsObject:(Session *)value;
- (void)addSessions:(NSSet *)value;
- (void)removeSessions:(NSSet *)value;

- (void)addChildrenObject:(Profile *)value;
- (void)removeChildrenObject:(Profile *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;

@end

