//
//  NTFSSubscription.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc, NTFSSubscription;

@protocol NTFSSubscriptionDelegateProtocol <NSObject>
- (void)subscriptionWasModified:(NTFSSubscription*)subscription;
@end

@interface NTFSSubscription : NSObject 
{
	id<NTFSSubscriptionDelegateProtocol> mv_delegate;
	
    NTFileDesc* mv_desc;
	NSNumber* mv_uniqueID;
}

+ (NTFSSubscription*)subscription:(NTFileDesc*)desc delegate:(id<NTFSSubscriptionDelegateProtocol>)delegate;
- (void)invalidate;

- (NSNumber *)uniqueID;

- (NTFileDesc *)desc;
- (void)setDesc:(NTFileDesc *)theDesc;

@end

@interface NTFSSubscription (MustSubclass)
- (void)subscribe;
- (void)unsubscribe;
@end

@interface NTFSSubscription (PrivateSubclassAccess)
- (id<NTFSSubscriptionDelegateProtocol>)delegate;
- (void)setDelegate:(id<NTFSSubscriptionDelegateProtocol>)theDelegate;
@end

@interface NTFSSubscription (NTFSMonitor)
- (void)subscriptionWasModified;
@end
