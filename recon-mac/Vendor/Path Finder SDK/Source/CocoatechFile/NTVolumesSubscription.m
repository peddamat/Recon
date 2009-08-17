//
//  NTVolumesSubscription.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTVolumesSubscription.h"
#import "NTVolumesMonitor.h"

@implementation NTVolumesSubscription
@end

@implementation NTVolumesSubscription (NTFNMonitor)

@end

@implementation NTVolumesSubscription (MustSubclass)

- (void)subscribe;
{
	[[NTVolumesMonitor sharedInstance] add:self];
}

- (void)unsubscribe;
{
	[[NTVolumesMonitor sharedInstance] remove:self];
}

@end

