//
//  Port_Script.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Port;

@interface Port_Script :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * output;
@property (nonatomic, retain) Port * port;

@end



