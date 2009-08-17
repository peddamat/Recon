//
//  NTPermissionsUIController.h
//  PermissionsModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@class NTPermissionsUIModel;

@interface NTPermissionsUIController : NSObject 
{
	IBOutlet NSView* mContentView;
	IBOutlet NSView* mVolumeView;
	IBOutlet NSObjectController* mObjectController;
	IBOutlet NSArrayController* mUsersArrayController;
	IBOutlet NSArrayController* mGroupsArrayController;

	NTThreadRunner* mThreadRunner;	
	
	id<NTPathFinderPluginHostProtocol> host;
		
	NSTabView* mTabView;
	
	NSView* mView;
	NTPermissionsUIModel* mModel;
	
	// ignore ownership tool calls
	NSNumber* mQueryIgnoreOwnershipToolID;
	NSNumber* mModifyIgnoreOwnershipToolID;
	BOOL mModifyingModel;
}

@property (retain) id<NTPathFinderPluginHostProtocol> host;

+ (NTPermissionsUIController*)controller:(id<NTPathFinderPluginHostProtocol>)host;

- (void)invalidate; // called so we can be dealloced, retained by objectController
- (NSView *)view;
- (NSMenu*)menu;

- (void)selectionUpdated:(NSArray*)items;

@end
