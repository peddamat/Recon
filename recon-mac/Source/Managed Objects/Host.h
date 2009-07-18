//
//  Host.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class OperatingSystem;
@class Port;
@class Session;

@interface Host :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * ipv4Address;
@property (nonatomic, retain) NSString * macAddress;
@property (nonatomic, retain) NSString * uptimeLastBoot;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * hostname;
@property (nonatomic, retain) NSString * statusReason;
@property (nonatomic, retain) NSString * distance;
@property (nonatomic, retain) NSString * uptimeSeconds;
@property (nonatomic, retain) NSSet* operatingsystems;
@property (nonatomic, retain) NSSet* ports;
@property (nonatomic, retain) Session * session;

@end


@interface Host (CoreDataGeneratedAccessors)
- (void)addOperatingsystemsObject:(OperatingSystem *)value;
- (void)removeOperatingsystemsObject:(OperatingSystem *)value;
- (void)addOperatingsystems:(NSSet *)value;
- (void)removeOperatingsystems:(NSSet *)value;

- (void)addPortsObject:(Port *)value;
- (void)removePortsObject:(Port *)value;
- (void)addPorts:(NSSet *)value;
- (void)removePorts:(NSSet *)value;

@end

