//
//  NTFSWatcher.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFSWatcher.h"
#import "NTFSWatcherItem.h"
#import "NTKQueueMonitor.h"
#import "NTFileEnvironment.h"

@interface NTFSWatcher (Private)
- (id<NTFSWatcherDelegateProtocol>)delegate;
- (void)setDelegate:(id<NTFSWatcherDelegateProtocol>)theDelegate;

- (NSMutableArray *)items;
- (void)setItems:(NSMutableArray *)theItems;

- (NSMutableDictionary *)descsToNotify;
- (void)setDescsToNotify:(NSMutableDictionary *)theDescsToNotify;

- (BOOL)sendingDelayedNotification;
- (void)setSendingDelayedNotification:(BOOL)flag;
@end

@interface NTFSWatcher (Protocols) <NTFSWatcherItemDelegateProtocol>
@end

@implementation NTFSWatcher

- (id)init;
{
	self = [super init];
	
	[self setItems:[NSMutableArray array]];

	return self;
}

- (void)dealloc
{
	if ([self delegate])
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];
	
	[self removeAll];
	
	[self setDescsToNotify:nil];
	[self setItems:nil];

    [super dealloc];
}

+ (NTFSWatcher*)watcher:(id<NTFSWatcherDelegateProtocol>)delegate;
{
	NTFSWatcher* result = [[NTFSWatcher alloc] init];
	
	[result setDelegate:delegate];
	
	return [result autorelease];
}

- (void)clearDelegate;
{
	[self setDelegate:nil];
}

- (void)refreshDescs;  // update the descs so we can check for hasBeenModified etc
{
	for (NTFSWatcherItem* item in [self items])
		[item refreshDesc];
}

// files/directories I'm watching
- (NSArray*)watchedDescs;
{
	NSMutableArray* result = [NSMutableArray array];
	
	for (NTFSWatcherItem* item in [self items])
		[result addObject:[item desc]];
	
	return result;
}

// replaces (removeAll, add)
- (void)watchItems:(NSArray*)items;
{
    [self removeAll];
	[self addItems:items];
}

- (void)addItem:(NTFileDesc*)desc;
{
	NTFSWatcherItem* item = [NTFSWatcherItem itemWithDesc:desc delegate:self];

	if (item)
	{
		// 500 limit. If the user selects a huge folder I don't want my selection monitoring code to bog down the system
		if ([[self items] count] < 500)
			[[self items] addObject:item];
		else
		{
			// we must clear delegate if we aren't going to use it
			[item clearDelegate];
		}
	}
}

- (void)addItems:(NSArray*)descs;
{
	id obj;
	
	for (obj in descs)
		[self addItem:obj];
}

- (void)removeItem:(NTFileDesc*)desc;
{
	NSEnumerator *enumerator = [[self items] reverseObjectEnumerator]; // modifying array while looping, go in reverse
	NTFSWatcherItem* item;
	
	while (item = [enumerator nextObject])
	{
		if ([[item desc] isEqualToDesc:desc])
		{
			[item clearDelegate];
			[[self items] removeObject:item];
			
			// remove any delayed notifications for this desc
			[[self descsToNotify] safeRemoveObjectForKey:[desc dictionaryKey]];
		}
	}
}

- (void)removeItems:(NSArray*)descs;
{
	NTFileDesc* desc;
	
	for (desc in descs)
		[self removeItem:desc];	
}

- (void)removeAll;
{
	[self removeItems:[self watchedDescs]];
}

@end

@implementation NTFSWatcher (Private)

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTFSWatcherDelegateProtocol>)delegate
{
    return mDelegate; 
}

- (void)setDelegate:(id<NTFSWatcherDelegateProtocol>)theDelegate
{
    if (mDelegate != theDelegate) {
        mDelegate = theDelegate; // not retained
    }
}

//---------------------------------------------------------- 
//  items 
//---------------------------------------------------------- 
- (NSMutableArray *)items
{
    return mItems; 
}

- (void)setItems:(NSMutableArray *)theItems
{
    if (mItems != theItems) {
        [mItems release];
        mItems = [theItems retain];
    }
}

//---------------------------------------------------------- 
//  descsToNotify 
//---------------------------------------------------------- 
- (NSMutableDictionary *)descsToNotify
{
	if (!mDescsToNotify)
		[self setDescsToNotify:[NSMutableDictionary dictionary]];

    return mDescsToNotify; 
}

- (void)setDescsToNotify:(NSMutableDictionary *)theDescsToNotify
{
    if (mDescsToNotify != theDescsToNotify) {
        [mDescsToNotify release];
        mDescsToNotify = [theDescsToNotify retain];
    }
}

//---------------------------------------------------------- 
//  sendingDelayedNotification 
//---------------------------------------------------------- 
- (BOOL)sendingDelayedNotification
{
    return mSendingDelayedNotification;
}

- (void)setSendingDelayedNotification:(BOOL)flag
{
    mSendingDelayedNotification = flag;
}

- (void)delayedNotification:(id)object;
{
	if (FENV(debugFSWatcher))
		IN_M;
	
	NSArray *tmp = [[self descsToNotify] safeAllValues];
	[[self descsToNotify] safeRemoveAllObjects];

	[[self delegate] watcher:self itemsChanged:tmp];
	
	if (FENV(debugFSWatcher))
		NSLog(@"notified: %@", [tmp description]);
		
	[self setSendingDelayedNotification:NO];
}

@end

@implementation NTFSWatcher (Protocols)

// NTFSWatcherItemDelegateProtocol
- (void)watcherItemWasModified:(NTFSWatcherItem*)watcherItem;
{
	NTFileDesc* desc = [watcherItem desc];
	NSString* key = [desc dictionaryKey];
		
	// avoid duplicates	
	if (![[self descsToNotify] safeObjectForKey:key])
	{
		[[self descsToNotify] safeSetObject:desc forKey:key];	
		
		if (![self sendingDelayedNotification])
		{
			[self setSendingDelayedNotification:YES];
			[self performSelector:@selector(delayedNotification:) withObject:nil afterDelay:.25];
		}
	}
}

@end

