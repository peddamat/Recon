//
//  Session.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Profile;
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
@property (nonatomic, retain) NSSet* hosts;

@end


@interface Session (CoreDataGeneratedAccessors)
- (void)addHostsObject:(Host *)value;
- (void)removeHostsObject:(Host *)value;
- (void)addHosts:(NSSet *)value;
- (void)removeHosts:(NSSet *)value;

@end

