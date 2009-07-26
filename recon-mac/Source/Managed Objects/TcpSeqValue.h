//
//  TcpSeqValue.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Host;

@interface TcpSeqValue :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) Host * host;

@end



