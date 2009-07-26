//
//  OsClass.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Host;

@interface OsClass :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * accuracy;
@property (nonatomic, retain) NSString * family;
@property (nonatomic, retain) NSString * vendor;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * gen;
@property (nonatomic, retain) Host * host;

@end



