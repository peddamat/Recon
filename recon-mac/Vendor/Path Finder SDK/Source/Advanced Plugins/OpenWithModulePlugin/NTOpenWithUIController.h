//
//  NTOpenWithUIController.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@class NTOpenWithUIModel;

@interface NTOpenWithUIController : NSObject 
{
	IBOutlet NSView* mContentView;
	IBOutlet NSObjectController* mObjectController;
	IBOutlet NSArrayController* mPopUpArrayController;
	
	NTThreadRunner* mThreadRunner;	
	id<NTPathFinderPluginHostProtocol> mHost;

	NSView* mView;
	NTOpenWithUIModel* mModel;
}

+ (NTOpenWithUIController*)controller:(id<NTPathFinderPluginHostProtocol>)host;

- (void)invalidate; // called so we can be dealloced, retained by objectController
- (NSView *)view;

- (void)selectionUpdated:(NSArray*)selection;

@end
