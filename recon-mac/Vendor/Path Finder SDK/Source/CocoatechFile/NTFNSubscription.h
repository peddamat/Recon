//
//  NTFNSubscription.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Feb 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTFSSubscription.h"

@interface NTFNSubscription : NTFSSubscription
{
    FNSubscriptionRef mv_subscriptionRef;
}

@end

@interface NTFNSubscription (NTFNMonitor)

// called from the NTFNMonitor
- (FNSubscriptionRef)subscriptionRef;
- (void)setSubscriptionRef:(FNSubscriptionRef)ref;

@end
