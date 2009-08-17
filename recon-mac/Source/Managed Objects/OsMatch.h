//
//  OsMatch.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Host;

@interface OsMatch :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * line;
@property (nonatomic, retain) NSString * accuracy;
@property (nonatomic, retain) Host * host;

@end



