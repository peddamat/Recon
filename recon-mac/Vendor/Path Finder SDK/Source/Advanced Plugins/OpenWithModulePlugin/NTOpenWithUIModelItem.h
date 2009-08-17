//
//  NTOpenWithUIModelItem.h
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 3/3/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTOpenWithUIModelItem : NSObject
{
	NTFileDesc* mDesc;

	int mCommand;
	NSString* mTitle;
	NSImage* mImage;
}

+ (NTOpenWithUIModelItem*)item:(NTFileDesc*)desc;
+ (NTOpenWithUIModelItem*)separator;
+ (NTOpenWithUIModelItem*)itemWithCommand:(int)command title:(NSString*)title;

- (NTFileDesc *)desc;
- (void)setDesc:(NTFileDesc *)theDesc;

- (int)command;
- (void)setCommand:(int)theCommand;

- (NSString *)title;
- (void)setTitle:(NSString *)theTitle;

- (NSImage *)image;
- (void)setImage:(NSImage *)theImage;

@end

