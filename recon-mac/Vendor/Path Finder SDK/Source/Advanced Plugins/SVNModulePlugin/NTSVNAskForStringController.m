//
//  NTSVNAskForStringController.m
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSVNAskForStringController.h"

@interface NTSVNAskForStringController (Private)
- (void)endPanel:(int)result;
- (void)run:(NSWindow*)sheetWindow;

- (id<NTSVNAskForStringControllerDelegate>)delegate;
- (void)setDelegate:(id<NTSVNAskForStringControllerDelegate>)theDelegate;

- (NSObjectController *)objectController;
- (void)setObjectController:(NSObjectController *)theObjectController;

- (NSMutableDictionary *)model;
- (void)setModel:(NSMutableDictionary *)theModel;

- (id)context;
- (void)setContext:(id)theContext;
@end

@implementation NTSVNAskForStringController

- (id)init;
{
	self = [super initWithWindowNibName:@"NTSVNAskForStringPanel"];
	
	return self;
}

+ (void)ask:(NSString*)title
sheetWindow:(NSWindow*)sheetWindow 
   delegate:(id<NTSVNAskForStringControllerDelegate>)delegate
	context:(id)context;
{
	NTSVNAskForStringController* windowController = [[NTSVNAskForStringController alloc] init];
	
	[windowController setDelegate:delegate];
	[windowController setContext:context];
	[[windowController model] setObject:title forKey:@"title"];

    [windowController run:sheetWindow];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setObjectController:nil];
    [self setModel:nil];
	[self setDelegate:nil];
    [self setContext:nil];

    [super dealloc];
}

@end

@implementation NTSVNAskForStringController (Actions)

- (void)OKButton:(id)sender;
{
	[self endPanel:NSOKButton];
}

- (void)cancelButton:(id)sender;
{
	[self endPanel:NSCancelButton];
}

@end

@implementation NTSVNAskForStringController (Private)

//---------------------------------------------------------- 
//  context 
//---------------------------------------------------------- 
- (id)context
{
    return mContext; 
}

- (void)setContext:(id)theContext
{
    if (mContext != theContext)
    {
        [mContext release];
        mContext = [theContext retain];
    }
}

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id<NTSVNAskForStringControllerDelegate>)delegate
{
    return mDelegate; 
}

- (void)setDelegate:(id<NTSVNAskForStringControllerDelegate>)theDelegate
{
    if (mDelegate != theDelegate)
    {
        [mDelegate release];
        mDelegate = [theDelegate retain];
    }
}

- (void)endPanel:(int)result;
{
    [[self window] orderOut:self];
	[NSApp endSheet:[self window] returnCode:result];
}

- (void)run:(NSWindow*)sheetWindow;
{
	[NSApp beginSheet:[self window]
	   modalForWindow: sheetWindow
		modalDelegate: self
	   didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// make sure bindings are flushed
	[sheet makeFirstResponder:nil];
	
	NSString *result = [[self model] objectForKey:@"message"];
	BOOL canceled = (returnCode == NSCancelButton);
	
	if (canceled)
		result = nil;
	
	[[self delegate] askForString_result:result canceled:canceled context:[self context]];
	
    [self close];
}

- (void)windowWillClose:(NSNotification *)notification
{
	// object controller retains us, must unbind to get released
	[[self objectController] unbind:@"contentObject"];
	
    [self autorelease];
}

- (void)windowDidLoad;
{	
}

//---------------------------------------------------------- 
//  objectController 
//---------------------------------------------------------- 
- (NSObjectController *)objectController
{
    return mObjectController; 
}

- (void)setObjectController:(NSObjectController *)theObjectController
{
    if (mObjectController != theObjectController)
    {
        [mObjectController release];
        mObjectController = [theObjectController retain];
    }
}

//---------------------------------------------------------- 
//  model 
//---------------------------------------------------------- 
- (NSMutableDictionary *)model
{
	if (!mModel)
		[self setModel:[NSMutableDictionary dictionary]];
	
    return mModel; 
}

- (void)setModel:(NSMutableDictionary *)theModel
{
    if (mModel != theModel)
    {
        [mModel release];
        mModel = [theModel retain];
    }
}

@end
