//
//  NTVolumesMonitor.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 7/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTVolumesMonitor.h"
#import "NTVolumeNotificationMgr.h"
#import "NTVolumesSubscription.h"
#import "NTFolderWatcher.h"
#import "NTDefaultDirectory.h"

@interface NTVolumesMonitor (Notifications) <NTFolderWatcherDelegateProtocol>
@end

@implementation NTVolumesMonitor

@synthesize watcher;

NTSINGLETONOBJECT_STORAGE  // subclass ok?

- (id)init;
{
	self = [super init];
	
	self.watcher = [NTFolderWatcher watcher:self folder:[[NTDefaultDirectory sharedInstance] computer] watchSubfolders:NO latency:0];

	return self;
}

- (void)dealloc;
{
	[self.watcher clearDelegate];
	self.watcher = nil;
	
	[super dealloc];
}

@end

@implementation NTVolumesMonitor (Notifications) 

// <NTFolderWatcherDelegateProtocol>

- (void)folderWatcher:(NTFolderWatcher*)theWatcher
			   folder:(NTFileDesc*)theFolder
			 messages:(NSArray*)theMessages;
{
	NSArray* values = [[self activeSubscriptions] allValues];
	
	NTVolumesSubscription* sub;
	
	for (sub in values)
		[self subscriptionWithUniqueIDWasModified:[[sub uniqueID] unsignedIntValue]];
}

@end
