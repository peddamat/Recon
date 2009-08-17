//
//  NTFSWatcherItem.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc, NTFSSubscription, NTFSWatcherItem;

@protocol NTFSWatcherItemDelegateProtocol <NSObject>
- (void)watcherItemWasModified:(NTFSWatcherItem*)watcherItem;
@end

@interface NTFSWatcherItem : NSObject 
{
	id<NTFSWatcherItemDelegateProtocol> mv_delegate;

	NTFileDesc* mv_desc;

	NTFSSubscription* mv_subscription;
}

+ (NTFSWatcherItem*)itemWithDesc:(NTFileDesc*)desc delegate:(id<NTFSWatcherItemDelegateProtocol>)delegate;
- (void)clearDelegate;

- (NTFileDesc*)desc;
- (void)refreshDesc;
@end
