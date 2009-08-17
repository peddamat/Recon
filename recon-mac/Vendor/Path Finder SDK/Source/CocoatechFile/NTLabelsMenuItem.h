//
//  NTLabelsMenuItem.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 4/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTLabelsMenuItem : NSView <NSCoding>
{
	NSArray* labelViews;
	NTStringView* labelText;
}

@property (retain) NSArray* labelViews;
@property (retain) NTStringView* labelText;

+ (NSMenuItem*)menuItem:(SEL)theAction target:(id)theTarget;
- (void)updateWithState:(NSDictionary*)theState;

// called internally
- (void)updateLabelText:(NSString*)theText;
@end
