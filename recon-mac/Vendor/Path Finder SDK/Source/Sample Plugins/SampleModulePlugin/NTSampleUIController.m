//
//  NTSampleUIController.m
//  SampleModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSampleUIController.h"
#import "NTSampleModuleThread.h"

@interface NTSampleUIController (hidden)
- (void)setView:(NSView *)theView;

- (NTSampleModuleThread *)thread;
- (void)setThread:(NTSampleModuleThread *)theThread;

- (int)nextThreadID;
@end

@interface NTSampleUIController (nibObjects)
- (NSView *)contentView;
- (void)setContentView:(NSView *)theContentView;

- (NSObjectController *)objectController;
- (void)setObjectController:(NSObjectController *)theObjectController;
@end

@interface NTSampleUIController (Private)
- (NSMutableDictionary *)model;
- (void)setModel:(NSMutableDictionary *)theModel;
@end

@interface NTSampleUIController (Protocols) <NTSampleModuleThreadDelegate>
@end

@implementation NTSampleUIController

+ (NTSampleUIController*)controller;
{
	NTSampleUIController* result = [[NTSampleUIController alloc] init];
	
	// load the prefs panel  nib
	if (![NSBundle loadNibNamed:@"UI" owner:result])
	{
		NSLog(@"Failed to load UI.nib");
		NSBeep();
	}
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setView:nil];
    [self setObjectController:nil];
	[self setModel:nil];
    [self setContentView:nil];
    [self setThread:nil];

    [super dealloc];
}

//---------------------------------------------------------- 
//  view 
//---------------------------------------------------------- 
- (NSView *)view
{
	if (!mView)
		[self setView:[self contentView]];

    return mView; 
}

- (void)setView:(NSView *)theView
{
    if (mView != theView)
    {
        [mView release];
        mView = [theView retain];
    }
}

- (void)invalidate; // called so we can be dealloced, retained by objectController
{
	[[self objectController] unbind:@"contentObject"];
}

- (void)selectionUpdated:(NSArray*)items;
{
	if (![items count])
		items = nil;
	
	if (items)
	{
		// start thread
		[self setThread:[NTSampleModuleThread thread:items delegate:self]];
	}
	else
		[self setModel:nil];	
}

@end

@implementation NTSampleUIController (Protocols) 

// NTSampleModuleThreadDelegate

// called on main thread
- (void)thread:(NTSampleModuleThread*)thread result:(NSArray*)result;
{
	if (thread == [self thread])
	{
		[[self model] setObject:result forKey:@"infoArray"];
		
		[self setThread:nil];
	}
}

@end

@implementation NTSampleUIController (Private)

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

//---------------------------------------------------------- 
//  thread 
//---------------------------------------------------------- 
- (NTSampleModuleThread *)thread
{
    return mThread; 
}

- (void)setThread:(NTSampleModuleThread *)theThread
{
    if (mThread != theThread)
    {
        [mThread clearDelegate];
		
        [mThread release];
        mThread = [theThread retain];
    }
}

@end

@implementation NTSampleUIController (nibObjects)

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
		[mObjectController release];  // top level object in nib, must release twice

		mObjectController = [theObjectController retain];
    }
}

//---------------------------------------------------------- 
//  contentView 
//---------------------------------------------------------- 
- (NSView *)contentView
{
    return mContentView; 
}

- (void)setContentView:(NSView *)theContentView
{
    if (mContentView != theContentView)
    {
        [mContentView release];
        [mContentView release];  // top level object in nib, must release twice
		
        mContentView = [theContentView retain];
    }
}

@end

