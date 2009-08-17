//
//  NTiTunesUIController.h
//  iTunesModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@class NTITunesDataModel, NTiTunesUIModel;

@interface NTiTunesUIController : NSObject 
{
	id<NTPathFinderPluginHostProtocol> mHost;

	IBOutlet NSView* mContentView;
	IBOutlet NSView* mLeftView;
	IBOutlet NSView* mRightView;
	IBOutlet NSView* mToolbarView;
	IBOutlet NSObjectController* mObjectController;
	IBOutlet NSObjectController* UIModelObjectController;
	IBOutlet NSArrayController* mTracksArrayController;
	IBOutlet NSArrayController* mArtistsArrayController;
	IBOutlet NSArrayController* mListTypeArrayController;
	NSSplitView* splitView;
	NTSplitViewDelegate* splitViewDelegate;
	BOOL haveSetupSplitview;
	
	NSView* mView;
	int mToolbarHeight;
	
	NTITunesDataModel *mModel;
	
	NTiTunesUIModel* UIModel;
}

@property (retain) NSSplitView* splitView;
@property (retain) NTSplitViewDelegate* splitViewDelegate;
@property (assign) BOOL haveSetupSplitview;
@property (retain) NTiTunesUIModel* UIModel;

+ (NTiTunesUIController*)controller:(id<NTPathFinderPluginHostProtocol>)host;

- (void)invalidate; // called so we can be dealloced, retained by objectController
- (NSView *)view;

@end
