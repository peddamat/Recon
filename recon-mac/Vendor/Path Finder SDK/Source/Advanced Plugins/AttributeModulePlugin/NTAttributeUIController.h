//
//  NTAttributeUIController.h
//  AttributeModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@class NTAttributeUIModel;

@interface NTAttributeUIController : NSObject 
{
	IBOutlet NSView* mContentView;
	IBOutlet NSView* mDatesView;
	IBOutlet NSObjectController* mObjectController;

	NSView* mView;
	NSTabView* mTabView;
	NTAttributeUIModel* mModel;

	id<NTPathFinderPluginHostProtocol> host;
	
	NTThreadRunner* mThreadRunner;	
}

@property (retain) id<NTPathFinderPluginHostProtocol> host;

+ (NTAttributeUIController*)controller:(id<NTPathFinderPluginHostProtocol>)theHost;

- (void)invalidate; // called so we can be dealloced, retained by objectController
- (NSView *)view;
- (NSMenu*)menu;

- (void)selectionUpdated:(NSArray*)items;

- (NSArray*)selection;
- (NTFileDesc*)selectedItem;

@end
