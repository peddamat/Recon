//
//  Port.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Host;
@class Port_Script;

@interface Port :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSString * serviceMethod;
@property (nonatomic, retain) NSString * serviceOsType;
@property (nonatomic, retain) NSString * serviceProduct;
@property (nonatomic, retain) NSString * stateReasonTTL;
@property (nonatomic, retain) NSString * serviceDeviceType;
@property (nonatomic, retain) NSString * stateReason;
@property (nonatomic, retain) NSString * protocol;
@property (nonatomic, retain) NSString * serviceName;
@property (nonatomic, retain) NSString * serviceConf;
@property (nonatomic, retain) NSString * serviceVersion;
@property (nonatomic, retain) Host * host;
@property (nonatomic, retain) NSSet* scripts;

@end


@interface Port (CoreDataGeneratedAccessors)
- (void)addScriptsObject:(Port_Script *)value;
- (void)removeScriptsObject:(Port_Script *)value;
- (void)addScripts:(NSSet *)value;
- (void)removeScripts:(NSSet *)value;

@end

