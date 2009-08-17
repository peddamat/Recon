//
//  NTFSMonitor.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFSSubscription;

@interface NTFSMonitor : NTSingletonObject
{
	NSMutableDictionary* mv_activeSubscriptions;
}

- (void)add:(NTFSSubscription*)subscription;
- (void)remove:(NTFSSubscription*)subscription;

@end

// accessed by subclasses
@interface NTFSMonitor (PrivateSubclassAccess)
- (void)subscriptionWithUniqueIDWasModified:(unsigned int)uniqueID;

- (NSMutableDictionary *)activeSubscriptions;
- (void)setActiveSubscriptions:(NSMutableDictionary *)theActiveSubscriptions;
@end
