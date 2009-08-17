//
//  Host.h
//  recon
//
//  Created by Sumanth Peddamatham on 8/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TcpSeqValue;
@class OsMatch;
@class Port;
@class TcpTsSeqValue;
@class Session;
@class OsClass;
@class IpIdSeqValue;

@interface Host :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * macAddress;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * ipIdSequenceClass;
@property (nonatomic, retain) NSString * distance;
@property (nonatomic, retain) NSString * statusReason;
@property (nonatomic, retain) NSString * tcpSequenceIndex;
@property (nonatomic, retain) NSString * tcpTsSequenceClass;
@property (nonatomic, retain) NSString * uptimeSeconds;
@property (nonatomic, retain) NSString * ipv4Address;
@property (nonatomic, retain) NSString * uptimeLastBoot;
@property (nonatomic, retain) NSString * tcpSequenceDifficulty;
@property (nonatomic, retain) NSString * hostname;
@property (nonatomic, retain) NSSet* tcpsequencevalues;
@property (nonatomic, retain) NSSet* osmatches;
@property (nonatomic, retain) NSSet* ports;
@property (nonatomic, retain) NSSet* tcptssequencevalues;
@property (nonatomic, retain) NSSet* notes;
@property (nonatomic, retain) Session * session;
@property (nonatomic, retain) NSSet* osclasses;
@property (nonatomic, retain) NSSet* ipidsequencevalues;

@end


@interface Host (CoreDataGeneratedAccessors)
- (void)addTcpsequencevaluesObject:(TcpSeqValue *)value;
- (void)removeTcpsequencevaluesObject:(TcpSeqValue *)value;
- (void)addTcpsequencevalues:(NSSet *)value;
- (void)removeTcpsequencevalues:(NSSet *)value;

- (void)addOsmatchesObject:(OsMatch *)value;
- (void)removeOsmatchesObject:(OsMatch *)value;
- (void)addOsmatches:(NSSet *)value;
- (void)removeOsmatches:(NSSet *)value;

- (void)addPortsObject:(Port *)value;
- (void)removePortsObject:(Port *)value;
- (void)addPorts:(NSSet *)value;
- (void)removePorts:(NSSet *)value;

- (void)addTcptssequencevaluesObject:(TcpTsSeqValue *)value;
- (void)removeTcptssequencevaluesObject:(TcpTsSeqValue *)value;
- (void)addTcptssequencevalues:(NSSet *)value;
- (void)removeTcptssequencevalues:(NSSet *)value;

- (void)addNotesObject:(NSManagedObject *)value;
- (void)removeNotesObject:(NSManagedObject *)value;
- (void)addNotes:(NSSet *)value;
- (void)removeNotes:(NSSet *)value;

- (void)addOsclassesObject:(OsClass *)value;
- (void)removeOsclassesObject:(OsClass *)value;
- (void)addOsclasses:(NSSet *)value;
- (void)removeOsclasses:(NSSet *)value;

- (void)addIpidsequencevaluesObject:(IpIdSeqValue *)value;
- (void)removeIpidsequencevaluesObject:(IpIdSeqValue *)value;
- (void)addIpidsequencevalues:(NSSet *)value;
- (void)removeIpidsequencevalues:(NSSet *)value;

@end

