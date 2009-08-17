//
//  NTLabelColorMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Feb 19 2002.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTLabelsModel, NTLabelLazyMenu;

#define NTLabelColorMgrNotification @"NTLabelColorMgrNotification"

@interface NTLabelColorMgr : NTSingletonObject
{
    NTLabelsModel* mLabelsModel;
	NSArray* mLabelOrder;
	
	NTLabelLazyMenu *mLabelMenu;
	NTLabelLazyMenu *mSmallLabelMenu;
}

- (NTLabelLazyMenu *)labelMenu;
- (NTLabelLazyMenu *)smallLabelMenu;

- (NSMenu*)labelPopUpMenu; // tags for labels, no action set

- (NSColor*)color:(int)label;
- (NTGradientDraw*)gradient:(int)label;
- (NSString*)label:(int)label;

- (int)labelAtIndex:(int)label;
- (int)indexForLabel:(int)label;
- (NSArray *)labelOrder;

- (NSComparisonResult)compare:(int)label1 label2:(int)label2;

- (NSDictionary*)dictionary; // used for bindings
- (void)restoreDefaults;

// so we know when to rebuild lazy menu
- (unsigned)buildID;
- (void)buildLabelsMenu:(NSMenu*)menu fontSize:(int)fontSize action:(SEL)action;

@end
