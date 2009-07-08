//
//  Host.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/6/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import <CoreData/CoreData.h>

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
@property (nonatomic, retain) NSString * uptimeSeconds;
@property (nonatomic, retain) NSSet* ports;
@property (nonatomic, retain) Session * session;

// User-defined instance variables
@property (readonly) NSString *ipAndHostname;

@end


@interface Host (CoreDataGeneratedAccessors)
- (void)addPortsObject:(Port *)value;
- (void)removePortsObject:(Port *)value;
- (void)addPorts:(NSSet *)value;
- (void)removePorts:(NSSet *)value;

@end

