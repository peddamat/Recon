//
//  NTFSMonitor.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFSMonitor.h"
#import "NTFSSubscription.h"

@implementation NTFSMonitor

- (id)init;
{
	self = [super init];
	
	[self setActiveSubscriptions:[NSMutableDictionary dictionary]];

	return self;
}

- (void)dealloc;
{
	[self setActiveSubscriptions:nil];
	[super dealloc];
}

- (void)add:(NTFSSubscription*)subscription;
{
	[[self activeSubscriptions] setObject:subscription forKey:[subscription uniqueID]];
}

- (void)remove:(NTFSSubscription*)subscription;
{	
	[[self activeSubscriptions] removeObjectForKey:[subscription uniqueID]];
}

@end

@implementation NTFSMonitor (CalledFromSubclasses)

- (void)subscriptionWithUniqueIDWasModified:(unsigned int)uniqueID;
{
	NTFSSubscription* subscription = [[self activeSubscriptions] objectForKey:[NSNumber numberWithUnsignedInt:uniqueID]];
	
	if (subscription)
		[subscription subscriptionWasModified];
}

//---------------------------------------------------------- 
//  activeSubscriptions 
//---------------------------------------------------------- 
- (NSMutableDictionary *)activeSubscriptions
{
    return mv_activeSubscriptions; 
}

- (void)setActiveSubscriptions:(NSMutableDictionary *)theActiveSubscriptions
{
    if (mv_activeSubscriptions != theActiveSubscriptions) {
        [mv_activeSubscriptions release];
        mv_activeSubscriptions = [theActiveSubscriptions retain];
    }
}

@end
