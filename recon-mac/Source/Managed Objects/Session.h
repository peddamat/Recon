//
//  Session.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/8/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Profile;
@class Port;
@class Host;

@interface Session :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * hostsUp;
@property (nonatomic, retain) NSString * target;
@property (nonatomic, retain) NSString * UUID;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSNumber * hostsDown;
@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * hostsTotal;
@property (nonatomic, retain) Profile * profile;
@property (nonatomic, retain) NSSet* ports;
@property (nonatomic, retain) NSSet* hosts;

@end


@interface Session (CoreDataGeneratedAccessors)
- (void)addPortsObject:(Port *)value;
- (void)removePortsObject:(Port *)value;
- (void)addPorts:(NSSet *)value;
- (void)removePorts:(NSSet *)value;

- (void)addHostsObject:(Host *)value;
- (void)removeHostsObject:(Host *)value;
- (void)addHosts:(NSSet *)value;
- (void)removeHosts:(NSSet *)value;

@end

