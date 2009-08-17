//
//  NTSizeUIModel.h
//  SizeModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTSizeUIModel : NSObject 
{
	NSString* mName;
	NSString* mInfo;
	NSString* mSize;
	NSImage* mIcon;
	NSString* mSizeToolTip;
}

+ (NTSizeUIModel*)model;

- (NSString *)name;
- (void)setName:(NSString *)theName;

- (NSString *)info;
- (void)setInfo:(NSString *)theInfo;

- (NSString *)size;
- (void)setSize:(NSString *)theSize;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)theIcon;

- (NSString *)sizeToolTip;
- (void)setSizeToolTip:(NSString *)theSizeToolTip;

@end
