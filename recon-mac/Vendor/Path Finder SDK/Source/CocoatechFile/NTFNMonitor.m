//
//  NTFNMonitor.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFNMonitor.h"
#import "NTFNSubscription.h"

void subscriptionProc(FNMessage message, OptionBits flags, void *refcon, FNSubscriptionRef subscription);

@implementation NTFNMonitor

NTSINGLETONOBJECT_STORAGE

- (id)init;
{
	self = [super init];
	
	mv_upp = NewFNSubscriptionUPP(subscriptionProc);

	return self;
}

- (void)dealloc; 
{
	if (mv_upp)
	{
		DisposeFNSubscriptionUPP(mv_upp);
		mv_upp = nil;
	}
	
	[super dealloc];
}

// subclassed
- (void)add:(NTFSSubscription*)subscription;
{
	FNSubscriptionRef outSubscription;
	
	OSStatus err = FNSubscribe([[subscription desc] FSRefPtr], mv_upp, (void*)[[subscription uniqueID] unsignedIntegerValue], (kFNNoImplicitAllSubscription | kFNNotifyInBackground), &outSubscription);
	if (!err)
		[(NTFNSubscription*)subscription setSubscriptionRef:outSubscription];

	[super add:subscription];
}

// subclassed
- (void)remove:(NTFSSubscription*)subscription;
{
	FNSubscriptionRef ref = [(NTFNSubscription*)subscription subscriptionRef];
	
	if (ref)
		FNUnsubscribe(ref);
	
	[super remove:subscription];
}

@end

void subscriptionProc(FNMessage message, OptionBits flags, void *refcon, FNSubscriptionRef subscription)
{
    if (message == kFNDirectoryModifiedMessage)
    {
		NSUInteger uniqueID = (NSUInteger)refcon;
        
		[[NTFNMonitor sharedInstance] subscriptionWithUniqueIDWasModified:uniqueID];
    }
}

