//
//  NTLabelLazyMenu.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTLabelLazyMenu.h"
#import "NTLabelColorMgr.h"

@interface NTLabelLazyMenu (Private)
@end

@implementation NTLabelLazyMenu

- (id)initWithTitle:(NSString*)title;
{
	self = [super initWithTitle:title];
	
	return self;
}

- (void)menuNeedsUpdate:(NSMenu*)menu;
{
	if ([self buildID] != [[NTLabelColorMgr sharedInstance] buildID])
	{
		[self setBuildID:[[NTLabelColorMgr sharedInstance] buildID]];

		// we want autoenabling on? slower, but not too bad
		[menu setAutoenablesItems:YES];
		[[NTLabelColorMgr sharedInstance] buildLabelsMenu:menu fontSize:[self fontSize] action:[self action]];
	}
}

- (BOOL)menuHasKeyEquivalent:(NSMenu*)menu forEvent:(NSEvent*)event target:(id*)target action:(SEL*)action;
{
	// bypass for speed!
	return NO;
}

@end

@implementation NTLabelLazyMenu (Private)

@end

