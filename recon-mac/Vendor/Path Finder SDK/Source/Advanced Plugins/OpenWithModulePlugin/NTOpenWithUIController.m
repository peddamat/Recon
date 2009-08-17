//
//  NTOpenWithUIController.m
//  OpenWithModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTOpenWithUIController.h"
#import "NTOpenWithUIModel.h"
#import "NTOpenWithUIModelThread.h"

@interface NTOpenWithUIController (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTOpenWithUIController (nibObjects)
- (NSView *)contentView;
- (void)setContentView:(NSView *)theContentView;

- (NSArrayController *)popUpArrayController;
- (void)setPopUpArrayController:(NSArrayController *)thePopUpArrayController;

- (NSObjectController *)objectController;
- (void)setObjectController:(NSObjectController *)theObjectController;
@end

@interface NTOpenWithUIController (Private)
- (NSView*)createView;

- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;

- (NTThreadRunner *)threadRunner;
- (void)setThreadRunner:(NTThreadRunner *)theThreadRunner;

- (NTOpenWithUIModel *)model;
- (void)setModel:(NTOpenWithUIModel *)theModel;
@end

@interface NTOpenWithUIController (Protocols) <NTThreadRunnerDelegateProtocol>
@end

@implementation NTOpenWithUIController

+ (NTOpenWithUIController*)controller:(id<NTPathFinderPluginHostProtocol>)host;
{
	NTOpenWithUIController* result = [[NTOpenWithUIController alloc] init];
	
	[result setHost:host];
	
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
	[self setThreadRunner:nil];
	[self setHost:nil];
	[self setPopUpArrayController:nil];

    [super dealloc];
}

//---------------------------------------------------------- 
//  view 
//---------------------------------------------------------- 
- (NSView *)view
{
	if (!mView)
		[self setView:[self createView]];

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
	
	// if computer, don't do shit
	if (([items count] == 1) && [[items objectAtIndex:0] isComputer])
		items = nil;
	
	if ([items count])
	{
		// start thread
		[self setThreadRunner:[NTOpenWithUIModelThread thread:items delegate:self]];
	}
	else
		[self setModel:nil];	
}

@end

@implementation NTOpenWithUIController (Protocols)

// NTThreadRunnerDelegateProtocol
- (void)threadRunner_complete:(NTThreadRunner*)threadRunner;
{
	if (threadRunner == [self threadRunner])
	{
		NTOpenWithUIModelThread* param = (NTOpenWithUIModelThread*)[threadRunner param];
		
		// set our new model
		[self setModel:[param model]];
		
		// clear the thread, it's done
		[self setThreadRunner:nil];
	}
}

@end

@implementation NTOpenWithUIController (Private)

//---------------------------------------------------------- 
//  host 
//---------------------------------------------------------- 
- (id<NTPathFinderPluginHostProtocol>)host
{
    return mHost; 
}

- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost
{
    if (mHost != theHost)
    {
        [mHost release];
        mHost = [theHost retain];
    }
}

//---------------------------------------------------------- 
//  threadRunner 
//---------------------------------------------------------- 
- (NTThreadRunner *)threadRunner
{
	return mThreadRunner; 
}

- (void)setThreadRunner:(NTThreadRunner *)theThreadRunner
{
	if (mThreadRunner != theThreadRunner) {
		[mThreadRunner clearDelegate];
		
		[mThreadRunner release];
		mThreadRunner = [theThreadRunner retain];
	}
}

- (NSView*)createView;
{
	// create the scroller
	NSRect frame = NSZeroRect;
	frame.size = [NSScrollView frameSizeForContentSize:[[self contentView] frame].size hasHorizontalScroller:NO hasVerticalScroller:NO borderType:NSNoBorder];
	
    NSScrollView* result = [[[NSScrollView alloc] initWithFrame:frame] autorelease];
	[result setAutohidesScrollers:YES];
    [result setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [result setHasVerticalScroller:YES];
    [result setHasHorizontalScroller:YES];
    [result setBorderType:NSNoBorder];

	// make transparent
	if ([[self host] infoModule])
	{
		[[result contentView] setCopiesOnScroll:NO];
		[result setDrawsBackground:NO];
	}
	else	
		[(id)[self contentView] setDrawsBackground:YES];
	
    if ([result verticalScroller])
        [[result verticalScroller] setControlSize:NSSmallControlSize];
    if ([result horizontalScroller])
        [[result horizontalScroller] setControlSize:NSSmallControlSize];
	
	[result setDocumentView:[self contentView]];
	
	return result;
}

//---------------------------------------------------------- 
//  model 
//---------------------------------------------------------- 
- (NTOpenWithUIModel *)model
{
	if (!mModel)
		[self setModel:[NTOpenWithUIModel model]];
	
    return mModel; 
}

- (void)setModel:(NTOpenWithUIModel *)theModel
{
    if (mModel != theModel)
    {
        [mModel release];
        mModel = [theModel retain];
    }
}

- (void)changeAllButtonAction:(id)sender;
{
	NTFileDesc *appDesc = [[[self model] selectedItem] desc];
	
	if (appDesc && [appDesc isValid])
	{
		NTFileDesc* previousApplication = [NTFileDesc applicationForType:[[[self model] firstDesc] type] creator:[[[self model] firstDesc] creator] extension:[[[self model] firstDesc] extension]];
		
		if (previousApplication)
		{
			NSString* extension = [[[self model] firstDesc] extension];
			NSString* title, *message;
			
			title = [NTLocalizedString localize:@"Are you sure you want to change all your %@ documents to open with the application \"%@\"?" table:@"Get Info"];
			message = [NTLocalizedString localize:@"This change will apply to all %@ documents with %@ \"%@\"." table:@"Get Info"];
			
			title = [NSString stringWithFormat:title, [previousApplication displayName], [appDesc displayName]];
			
			// message is different if we don't have a file extension, uses the type in that case
			if ([extension length])
				message = [NSString stringWithFormat:message, [previousApplication displayName], [NTLocalizedString localize:@"extension" table:@"Get Info"], [[[self model] firstDesc] extension]];
			else
				message = [NSString stringWithFormat:message, [previousApplication displayName], [NTLocalizedString localize:@"type" table:@"Get Info"], [NTUtilities intToString:[[[self model] firstDesc] type]]];
			
			// simple sheet here
			[NTAlertPanel show:NSCriticalAlertStyle
						target:self
					  selector:@selector(changeApplicationBindingSelector:)
						 title:title
					   message:message
					   context:[appDesc retain]  // autoreleased in changeApplicationBindingSelector
						window:[[self contentView] window]];
		}
		else
		{
			// no previous application, just change it
			[NTFileAttributeModifier setApplicationBinding:appDesc forFilesLike:[[self model] firstDesc]];
		}
	}
}

- (void)changeApplicationBindingSelector:(NTAlertPanel*)sender;
{
    NTAlertPanel* panel = sender;
    NTFileDesc* appDesc = [sender contextInfo];
	
    // retained above, autorelease now
    [appDesc autorelease];
    
    if ([panel resultCode] == NSAlertFirstButtonReturn)
    {        
        if (appDesc && [appDesc isValid])
            [NTFileAttributeModifier setApplicationBinding:appDesc forFilesLike:[[self model] firstDesc]];
    }
}

@end

@implementation NTOpenWithUIController (nibObjects)

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
		[mContentView release];  // top level nib object, must release twice
		
        mContentView = [theContentView retain];
    }
}

//---------------------------------------------------------- 
//  popUpArrayController 
//---------------------------------------------------------- 
- (NSArrayController *)popUpArrayController
{
    return mPopUpArrayController; 
}

- (void)setPopUpArrayController:(NSArrayController *)thePopUpArrayController
{
    if (mPopUpArrayController != thePopUpArrayController)
    {
        [mPopUpArrayController release];
		[mPopUpArrayController release];  // top level nib object, must release twice

        mPopUpArrayController = [thePopUpArrayController retain];
    }
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
		[mObjectController release];  // top level nib object, must release twice

        mObjectController = [theObjectController retain];
    }
}

@end
