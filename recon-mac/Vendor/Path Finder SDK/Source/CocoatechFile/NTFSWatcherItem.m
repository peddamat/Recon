//
//  NTFSWatcherItem.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFSWatcherItem.h"
#import "NTVolumesSubscription.h"
#import "NTFNSubscription.h"
#import "NTKQueueSubscription.h"
#import "NTFileDesc.h"
#import "NTVolume.h"

@interface NTFSWatcherItem (Private)
- (id<NTFSWatcherItemDelegateProtocol>)delegate;
- (void)setDelegate:(id<NTFSWatcherItemDelegateProtocol>)theDelegate;

- (NTFSSubscription *)subscription;
- (void)setSubscription:(NTFSSubscription *)theSubscription;

- (void)setDesc:(NTFileDesc *)theDesc;

- (BOOL)useKQueues;
@end

@interface NTFSWatcherItem (Protocols) <NTFSSubscriptionDelegateProtocol>
@end

@implementation NTFSWatcherItem

- (void)dealloc
{
	if ([self delegate])
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];

    [self setDesc:nil];
    [self setSubscription:nil];
	
    [super dealloc];
}

+ (NTFSWatcherItem*)itemWithDesc:(NTFileDesc*)desc delegate:(id<NTFSWatcherItemDelegateProtocol>)delegate;
{
	NTFSWatcherItem* result = nil;
	
	if ([desc isValid])
	{
		result = [[NTFSWatcherItem alloc] init];

		[result setDelegate:delegate];
		[result setDesc:desc];

		if ([desc isComputer])
			[result setSubscription:[NTVolumesSubscription subscription:[result desc] delegate:result]];
		else
		{			
			if ([result useKQueues])
				[result setSubscription:[NTKQueueSubscription subscription:[result desc] delegate:result]];
			else
				[result setSubscription:[NTFNSubscription subscription:[result desc] delegate:result]];
		}
	}
	
	return [result autorelease];
}	

- (void)clearDelegate;
{
	[self setDelegate:nil];
}

- (NTFileDesc *)desc
{
    return mv_desc; 
}

- (void)refreshDesc;
{
	[self setDesc:[[self desc] newDesc]];
}

@end

@implementation NTFSWatcherItem (Private)

- (BOOL)useKQueues;
{
	return ([[[self desc] volume] isHFS] || [[[self desc] volume] isUFS]);
}

//---------------------------------------------------------- 
//  desc 
//---------------------------------------------------------- 

- (void)setDesc:(NTFileDesc *)theDesc
{
    if (mv_desc != theDesc) {
        [mv_desc release];
        mv_desc = [theDesc retain];
    }
}

//---------------------------------------------------------- 
//  subscription 
//---------------------------------------------------------- 
- (NTFSSubscription *)subscription
{
    return mv_subscription; 
}

- (void)setSubscription:(NTFSSubscription *)theSubscription
{
    if (mv_subscription != theSubscription) {
		[mv_subscription invalidate];
		
        [mv_subscription release];
        mv_subscription = [theSubscription retain];
    }
}

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTFSWatcherItemDelegateProtocol>)delegate
{
    return mv_delegate; 
}

- (void)setDelegate:(id<NTFSWatcherItemDelegateProtocol>)theDelegate
{
    if (mv_delegate != theDelegate) {
        mv_delegate = theDelegate; // no retain
    }
}

@end

@implementation NTFSWatcherItem (Protocols)

// NTFSSubscriptionDelegateProtocol
- (void)subscriptionWasModified:(NTFSSubscription*)subscription;
{
	[[self delegate] watcherItemWasModified:self];
}

@end

