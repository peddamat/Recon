//
//  NTFSSubscription.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFSSubscription.h"

@interface NTFSSubscription (Private)
- (void)setUniqueID:(NSNumber *)theUniqueID;
@end

@implementation NTFSSubscription

- (id)init;
{
	self = [super init];
	
	static unsigned sUniqueID=1;
	[self setUniqueID:[NSNumber numberWithUnsignedInt:sUniqueID++]];
	
	return self;
}

- (void)dealloc
{
	if ([self delegate])
		[NSException raise:@"must call invalidate" format:@"%@", NSStringFromClass([self class])];

    [self setDesc:nil];
    [self setUniqueID:nil];
	
    [super dealloc];
}

+ (NTFSSubscription*)subscription:(NTFileDesc*)desc delegate:(id<NTFSSubscriptionDelegateProtocol>)delegate;
{
	NTFSSubscription* result = [[self alloc] init];
	
	[result setDelegate:delegate];
	[result setDesc:desc];
	[result subscribe];

	return [result autorelease];
}

- (void)invalidate;
{
	[self setDelegate:nil];
	
	[self unsubscribe];
}

//---------------------------------------------------------- 
//  uniqueID 
//---------------------------------------------------------- 
- (NSNumber *)uniqueID
{
    return mv_uniqueID; 
}

//---------------------------------------------------------- 
//  desc 
//---------------------------------------------------------- 
- (NTFileDesc *)desc
{
    return mv_desc; 
}

- (void)setDesc:(NTFileDesc *)theDesc
{
    if (mv_desc != theDesc) {
        [mv_desc release];
        mv_desc = [theDesc retain];
    }
}

@end

@implementation NTFSSubscription (Private)

- (void)setUniqueID:(NSNumber *)theUniqueID
{
    if (mv_uniqueID != theUniqueID) {
        [mv_uniqueID release];
        mv_uniqueID = [theUniqueID retain];
    }
}

@end

@implementation NTFSSubscription (MustSubclass)

- (void)subscribe;
{
	[NSException raise:@"must subclass" format:@"%@", NSStringFromClass([self class])];
}

- (void)unsubscribe;
{
	[NSException raise:@"must subclass" format:@"%@", NSStringFromClass([self class])];
}

@end

@implementation NTFSSubscription (PrivateSubclassAccess)

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTFSSubscriptionDelegateProtocol>)delegate
{
    return mv_delegate; 
}

- (void)setDelegate:(id<NTFSSubscriptionDelegateProtocol>)theDelegate
{
    if (mv_delegate != theDelegate) {
        mv_delegate = theDelegate; // don't retain
    }
}

@end

@implementation NTFSSubscription (NTFSMonitor)

- (void)subscriptionWasModified;
{	
	[[self delegate] subscriptionWasModified:self];
}

@end
