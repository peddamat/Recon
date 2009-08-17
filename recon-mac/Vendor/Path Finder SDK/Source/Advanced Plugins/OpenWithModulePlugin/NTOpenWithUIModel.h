//
//  NTOpenWithUIModel.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTOpenWithUIModelItem.h"

#define kChoosePopupCommand 44

@interface NTOpenWithUIModel : NSObject 
{
	BOOL mInitialized;
	BOOL mChangeAllEnabled;
	
	NSArray* mDescs;
	NSArray* mItems;
	id mSelectedItem;
}

+ (NTOpenWithUIModel*)model;

- (BOOL)initialized;
- (void)setInitialized:(BOOL)flag;

- (BOOL)changeAllEnabled;
- (void)setChangeAllEnabled:(BOOL)flag;

- (NTFileDesc*)firstDesc;
- (NSArray *)descs;
- (void)setDescs:(NSArray *)theDescs;

- (NSArray *)items;
- (void)setItems:(NSArray *)theItems;

- (id)selectedItem;
- (void)setSelectedItem:(id)theSelectedItem;

@end

