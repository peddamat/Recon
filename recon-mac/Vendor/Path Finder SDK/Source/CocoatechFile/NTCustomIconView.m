//
//  NTCustomIconView.m
//  CocoatechFoundation
//
//  Created by Steve Gehrman on Tue Aug 27 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTCustomIconView.h"
#import "NTIconFamily.h"
#import "NTIcon.h"
#import "NSImage-CocoatechFile.h"

@interface NTCustomIconView (Private)
@end

@interface NTCustomIconView (hidden)
- (NTFileDesc *)desc;
@end

@implementation NTCustomIconView

- (void)commonInit_NTCustomIconView;
{
    [self setImageScaling:NSScaleProportionally];
    [self setEditable:YES];
}	

- (id)initWithFrame:(NSRect)frame;
{
	self = [super initWithFrame:frame];
	
	[self commonInit_NTCustomIconView];
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
	self = [super initWithCoder:aDecoder];
	
	[self commonInit_NTCustomIconView];
	
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDesc:nil];
    [super dealloc];
}

//---------------------------------------------------------- 
//  desc 
//---------------------------------------------------------- 
- (NTFileDesc *)desc
{
    return mDesc; 
}

- (void)setDesc:(NTFileDesc *)theDesc
{
    if (mDesc != theDesc)
    {
        [mDesc release];
        mDesc = [theDesc retain];
    }
}

- (void)drawRect:(NSRect)rect;
{
    [super drawRect:rect];

    // draw focus border if first responder
    if ([[self window] isKeyWindow] && [[self window] firstResponder] == self)
        [self drawFocusRing];
}

- (IBAction)copy:(id)sender
{
	NTIconFamily* iconFamily = nil;
	
	if ([self desc])
		iconFamily = [NTIconFamily iconFamilyWithIconOfFile:[self desc]];

    if (iconFamily)
        [iconFamily putOnPasteboard];
}

- (IBAction)cut:(id)sender
{
    [self copy:self];

    [self clear:self];
}

- (IBAction)clear:(id)sender
{
    if ([[self desc] isDirectory])
        [NTIconFamily removeCustomIconFromDirectory:[self desc]];
    else
        [NTIconFamily removeCustomIconFromFile:[self desc]];
}

// [[NSWorkspace sharedWorkspace] setIcon:image forFile:fullPath options:0];

- (IBAction)paste:(id)sender
{
    // is items on the scrap good?
    if ([NTIconFamily canInitWithPasteboard])
    {		
		NTIconFamily* iconFamily = [NTIconFamily iconFamilyWithPasteboard];

        // set the files custom icon
        if ([[self desc] isDirectory])
            [iconFamily setAsCustomIconForDirectory:[self desc]];
        else
            [iconFamily setAsCustomIconForFile:[self desc]];
        
        // send our action to ourselves to tell the owner that the image changed
        if ([self action])
            [NSApp sendAction:[self action] to:[self target] from:self];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
{
	SEL action = [menuItem action];
	
	if (action == @selector(paste:))
		return [NTIconFamily canInitWithPasteboard];
	else if (action == @selector(cut:))
		return YES;
	else if (action == @selector(clear:))
		return YES;
	else if (action == @selector(copy:))
		return YES;

	return NO;
}

@end

@implementation NTCustomIconView (Private)

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *characters;

    characters = [theEvent characters];
    if ([characters length])
    {
        if ([characters characterAtIndex:0] == 127)
        {
            // delete key does a clear
            [self clear:self];
        }
    }
}

- (BOOL)acceptsFirstResponder;
{
	// only if current event is a mouseDown
	if ([[NSApp currentEvent] type] == NSLeftMouseDown)
		return YES;
	
	return NO;
}

@end
