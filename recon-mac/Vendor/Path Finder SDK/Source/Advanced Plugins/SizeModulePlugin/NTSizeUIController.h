//
//  NTSizeUIController.h
//  SizeModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTModulePluginProtocol.h"

@class NTSizeUIModel;

@interface NTSizeUIController : NSObject 
{
	IBOutlet NSObjectController* objectController;
	IBOutlet NSView* contentView;
	IBOutlet NSTextField* sizeTextField;  
	IBOutlet NSTextField* nameTextField;  
	IBOutlet NSTextField* attributesTextField;  
	IBOutlet NTCustomIconView* iconView;

	NTThreadRunner* mThreadRunner;	
	NTListSizeCalculator *mSizeCalculator;	

	id<NTPathFinderPluginHostProtocol> host;

	NSView* mView;
	NTSizeUIModel* model;
	
	NSProgressIndicator *mProgressIndicator;
}

@property (retain) IBOutlet NSObjectController* objectController;
@property (retain) IBOutlet NSView* contentView;
@property (retain) IBOutlet NSTextField *sizeTextField;
@property (retain) IBOutlet NSTextField *nameTextField;
@property (retain) IBOutlet NSTextField *attributesTextField;
@property (retain) IBOutlet NTCustomIconView *iconView;
@property (retain) NTSizeUIModel* model;
@property (retain) id<NTPathFinderPluginHostProtocol> host;

+ (NTSizeUIController*)controller:(id<NTPathFinderPluginHostProtocol>)host;

- (void)invalidate; // called so we can be dealloced, retained by objectController
- (NSView *)view;

- (void)selectionUpdated:(NSArray*)selection;

@end
