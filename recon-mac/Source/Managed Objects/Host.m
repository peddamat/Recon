// 
//  Host.m
//  recon
//
//  Created by Sumanth Peddamatham on 8/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Host.h"

#import "TcpSeqValue.h"
#import "OsMatch.h"
#import "Port.h"
#import "TcpTsSeqValue.h"
#import "Session.h"
#import "OsClass.h"
#import "IpIdSeqValue.h"

@implementation Host 

@dynamic macAddress;
@dynamic status;
@dynamic ipIdSequenceClass;
@dynamic distance;
@dynamic statusReason;
@dynamic tcpSequenceIndex;
@dynamic tcpTsSequenceClass;
@dynamic uptimeSeconds;
@dynamic ipv4Address;
@dynamic uptimeLastBoot;
@dynamic tcpSequenceDifficulty;
@dynamic hostname;
@dynamic tcpsequencevalues;
@dynamic osmatches;
@dynamic ports;
@dynamic tcptssequencevalues;
@dynamic notes;
@dynamic session;
@dynamic osclasses;
@dynamic ipidsequencevalues;

@end
