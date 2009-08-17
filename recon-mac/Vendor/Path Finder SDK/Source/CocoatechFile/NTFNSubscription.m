//
//  NTFNSubscription.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Feb 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NTFNSubscription.h"
#import "NTFNMonitor.h"

@implementation NTFNSubscription

@end

@implementation NTFNSubscription (NTFNMonitor)

- (void)setSubscriptionRef:(FNSubscriptionRef)ref;
{
	mv_subscriptionRef = ref;
}

- (FNSubscriptionRef)subscriptionRef;
{
	return mv_subscriptionRef;
}

@end

@implementation NTFNSubscription (MustSubclass)

- (void)subscribe;
{
	[[NTFNMonitor sharedInstance] add:self];
}

- (void)unsubscribe;
{
	[[NTFNMonitor sharedInstance] remove:self];
}

@end

