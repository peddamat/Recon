//
//  NTPermissionsUIController.m
//  PermissionsModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTPermissionsUIController.h"
#import "NTPermissionsUIModel.h"
#import "NTPermissionsUIModelThread.h"

@interface NTPermissionsUIController (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTPermissionsUIController (nibObjects)
- (NSObjectController *)objectController;
- (void)setObjectController:(NSObjectController *)theObjectController;

- (NSView *)contentView;
- (void)setContentView:(NSView *)theContentView;

- (NSView *)volumeView;
- (void)setVolumeView:(NSView *)theVolumeView;

- (NSArrayController *)usersArrayController;
- (void)setUsersArrayController:(NSArrayController *)theUsersArrayController;

- (NSArrayController *)groupsArrayController;
- (void)setGroupsArrayController:(NSArrayController *)theGroupsArrayController;
@end

@interface NTPermissionsUIController (Protocols) <NTThreadRunnerDelegateProtocol>
@end

@interface NTPermissionsUIController (Private)
- (BOOL)modifyingModel;
- (void)setModifyingModel:(BOOL)flag;

- (NSArray*)selection;

- (NSView*)createView;
- (NSString*)prefKey;
- (void)updateIgnoreOwnership:(NTFileDesc*)desc;

- (NSNumber *)queryIgnoreOwnershipToolID;
- (void)setQueryIgnoreOwnershipToolID:(NSNumber *)theQueryIgnoreOwnershipToolID;

- (NSNumber *)modifyIgnoreOwnershipToolID;
- (void)setModifyIgnoreOwnershipToolID:(NSNumber *)theModifyIgnoreOwnershipToolID;

- (NSTabView *)tabView;
- (void)setTabView:(NSTabView *)theTabView;

- (NTThreadRunner *)threadRunner;
- (void)setThreadRunner:(NTThreadRunner *)theThreadRunner;

- (NTPermissionsUIModel *)model;
- (void)setModel:(NTPermissionsUIModel *)theModel;

@end

@implementation NTPermissionsUIController

@synthesize host;

+ (NTPermissionsUIController*)controller:(id<NTPathFinderPluginHostProtocol>)theHost;
{
	NTPermissionsUIController* result = [[NTPermissionsUIController alloc] init];
	
	[result setHost:theHost];
		
	// a valid model must always be present since this gives the contents of the matrix
	[result setModel:[NTPermissionsUIModel model]];

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
	[self setTabView:nil];
    [self setVolumeView:nil];
    [self setQueryIgnoreOwnershipToolID:nil];
    [self setModifyIgnoreOwnershipToolID:nil];
	[self setUsersArrayController:nil];
    [self setGroupsArrayController:nil];

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
	
	if (items)
	{
		// start thread
		[self setThreadRunner:[NTPermissionsUIModelThread thread:items delegate:self]];
		
		// start task for volume shit
		if ([items count] == 1)
			[self updateIgnoreOwnership:[items objectAtIndex:0]];
	}
	else
	{
		// a valid model must always be present since this gives the contents of the matrix
		[self setModel:[NTPermissionsUIModel model]];	
	}
}

- (NSMenu*)menu;
{
	NSMenu* menu = [[NSMenu alloc] init];
	NSMenuItem* menuItem;
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Permissions" table:@"Get Info"] action:@selector(tabViewAction:) keyEquivalent:@""] autorelease];
	[menuItem setFontSize:kSmallMenuFontSize color:nil];
    [menuItem setTarget:self];
	[menuItem setTag:0];
    [menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Volume Permissions" table:@"Get Info"] action:@selector(tabViewAction:) keyEquivalent:@""] autorelease];
	[menuItem setFontSize:kSmallMenuFontSize color:nil];
	[menuItem setTarget:self];
    [menuItem setTag:1];
    [menu addItem:menuItem];
	
	return [menu autorelease];
}

@end

@implementation NTPermissionsUIController (Private)

//---------------------------------------------------------- 
//  queryIgnoreOwnershipToolID 
//---------------------------------------------------------- 
- (NSNumber *)queryIgnoreOwnershipToolID
{
    return mQueryIgnoreOwnershipToolID; 
}

- (void)setQueryIgnoreOwnershipToolID:(NSNumber *)theQueryIgnoreOwnershipToolID
{
    if (mQueryIgnoreOwnershipToolID != theQueryIgnoreOwnershipToolID)
    {
        [mQueryIgnoreOwnershipToolID release];
        mQueryIgnoreOwnershipToolID = [theQueryIgnoreOwnershipToolID retain];
    }
}

//---------------------------------------------------------- 
//  modifyIgnoreOwnershipToolID 
//---------------------------------------------------------- 
- (NSNumber *)modifyIgnoreOwnershipToolID
{
    return mModifyIgnoreOwnershipToolID; 
}

- (void)setModifyIgnoreOwnershipToolID:(NSNumber *)theModifyIgnoreOwnershipToolID
{
    if (mModifyIgnoreOwnershipToolID != theModifyIgnoreOwnershipToolID)
    {
        [mModifyIgnoreOwnershipToolID release];
        mModifyIgnoreOwnershipToolID = [theModifyIgnoreOwnershipToolID retain];
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
	// create tabview
	NSRect frame = [[self contentView] frame];
	[self setTabView:[[[NSTabView alloc] initWithFrame:frame] autorelease]];
    [[self tabView] setTabViewType:NSNoTabsNoBorder];
    [[self tabView] setAutoresizingMask:NSViewNotSizable];
	[[self tabView] setDrawsBackground:NO];
	
    NSTabViewItem* tab;
    
	tab = [[[NSTabViewItem alloc] initWithIdentifier:@"content"] autorelease];
    [tab setLabel:[NTLocalizedString localize:@"Content"]];
	
    [tab setView:[self contentView]];
    [[self tabView] addTabViewItem:tab];
	
    tab = [[[NSTabViewItem alloc] initWithIdentifier:@"volume"] autorelease];
    [tab setLabel:[NTLocalizedString localize:@"Volume"]];
    [tab setView:[self volumeView]];
    [[self tabView] addTabViewItem:tab];
	
	int index = [[NSUserDefaults standardUserDefaults] integerForKey:[self prefKey]];
	[[self tabView] selectTabViewItemAtIndex:index];
	
	// create the scroller
	frame = NSZeroRect;
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
	
	[result setDocumentView:[self tabView]];
	
	return result;
}

//---------------------------------------------------------- 
//  tabView 
//---------------------------------------------------------- 
- (NSTabView *)tabView
{
    return mTabView; 
}

- (void)setTabView:(NSTabView *)theTabView
{
    if (mTabView != theTabView)
    {
        [mTabView release];
        mTabView = [theTabView retain];
    }
}

//---------------------------------------------------------- 
//  model 
//---------------------------------------------------------- 
- (NTPermissionsUIModel *)model
{	
    return mModel; 
}

- (void)setModel:(NTPermissionsUIModel *)theModel
{
    if (mModel != theModel)
    {
		[mModel stopObserving:self];

        [mModel release];
        mModel = [theModel retain];
    }
}

- (NSString*)prefKey;
{
	return [NSString stringWithFormat:@"%@:%@:selectedTabIndex", [[self host] modulePrefKey], NSStringFromClass([self class])];
}

- (NSArray*)selection;
{
	NSString* syncToBrowserID = [[self host] syncToBrowserID];
	NSArray* selection = [[self host] selection:[[self view] window] browserID:syncToBrowserID];
	if (![selection count])
	{
		if ([[self host] inspectorModule])
		{
			NTFileDesc *dir = (NTFileDesc*) [[self host] currentDirectory:[[self view] window] browserID:syncToBrowserID];
			
			if (dir)
				selection = [NSArray arrayWithObject:dir];
		}
	}
	
	return selection;
}

- (void)observeValueForKeyPath:(NSString *)key
					  ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context;
{
	// ignore changes if we are modifying the model ourselves
	if ([self modifyingModel])
		return;
	
	if ([[self model] initialized])
	{
		NSArray *selection = [self selection];
		NTFileDesc* selectedItem = nil;
		
		if ([selection count])
			selectedItem = [selection objectAtIndex:0];
		
		// must have a selection
		if (selectedItem)
		{			
			if ([key isEqualToString:@"selectedPermissions"])
				[[self host] set:[NSNumber numberWithUnsignedInt:[[self model] selectedPermissionBits]] attributeID:kPermissions_attributeID items:selection];
			else if ([key isEqualToString:@"permissionOctalString"])
			{
				unsigned permBits = [[self model] permissionBitsFromOctalString];
				
				if (permBits != 0xFFFFFFFF)
					[[self host] set:[NSNumber numberWithUnsignedInt:permBits] attributeID:kPermissions_attributeID items:selection];
				else
					NSBeep();  // refresh?
			}
			else if ([key isEqualToString:@"group"])
				[[self host] set:[NSNumber numberWithInt:[[[self model] group] identifier]] attributeID:kGroup_attributeID items:selection];
			else if ([key isEqualToString:@"user"])
				[[self host] set:[NSNumber numberWithInt:[[[self model] user] identifier]] attributeID:kOwner_attributeID items:selection];
			else if ([key isEqualToString:@"ignoreOwnership"])
			{
				NSArray* args;
				
				if ([[self model] ignoreOwnership])
					args = [NSArray arrayWithObjects:@"-d", [selectedItem path], nil];
				else
					args = [NSArray arrayWithObjects:@"-a", [selectedItem path], nil];
				
				[self setModifyIgnoreOwnershipToolID:[[self host] runTool:@"/usr/sbin/vsdbutil"
														   directory:nil
														   arguments:args 
															  target:self
															  setUID:YES]];				
			}
		}
	}
}

- (void)updateIgnoreOwnership:(NTFileDesc*)desc;
{
	if ([desc isVolume])
	{
		NSArray* args = [NSArray arrayWithObjects:@"-c", [desc path], nil];
		
		[self setQueryIgnoreOwnershipToolID:[[self host] runTool:@"/usr/sbin/vsdbutil"
													   directory:nil
													   arguments:args 
														  target:self
														  setUID:NO]];				
	}
}

- (void)runTool_result:(NSDictionary*)dict;
{
	NSNumber* identifier = [dict objectForKey:@"identifier"];
	
	// is this one of our tools?  We must check, it could be another plugin
	if ([[self modifyIgnoreOwnershipToolID] isEqualTo:identifier])
	{
		// remove not needed anymore
		[self setModifyIgnoreOwnershipToolID:nil];
	}
	// is this one of our tools?  We must check, it could be another plugin
	else if ([[self queryIgnoreOwnershipToolID] isEqualTo:identifier])
	{
		NSString* outString = [dict objectForKey:@"result"];
		
		BOOL ignore = YES;
		
		// No entry found for '/Volumes/Development'.
		// Permissions on '/' are enabled.
		if ([outString rangeOfString:@"No entry found"].location != NSNotFound)
			ignore = YES;
		else if ([outString rangeOfString:@"are enabled"].location != NSNotFound)
			ignore = NO;
			
		[self setModifyingModel:YES];
		[[self model] setIgnoreOwnership:ignore];
		[self setModifyingModel:NO];
		
		// remove from launched tools
		[self setQueryIgnoreOwnershipToolID:nil];
	}
}

//---------------------------------------------------------- 
//  modifyingModel 
//---------------------------------------------------------- 
- (BOOL)modifyingModel
{
    return mModifyingModel;
}

- (void)setModifyingModel:(BOOL)flag
{
    mModifyingModel = flag;
}

@end

@implementation NTPermissionsUIController (Protocols)

// NTThreadRunnerDelegateProtocol
- (void)threadRunner_complete:(NTThreadRunner*)threadRunner;
{
	if (threadRunner == [self threadRunner])
	{
		NTPermissionsUIModelThread* param = (NTPermissionsUIModelThread*)[threadRunner param];
		
		// set our new model
		[self setModel:[param model]];
		
		// this is used for both control enabling and also to be able to tell when a setXXX call is because of a UI change
		[[self model] setInitialized:YES];
		[[self model] startObserving:self];
		
		// clear the thread, it's done
		[self setThreadRunner:nil];
	}
}

@end

@implementation NTPermissionsUIController (Actions)

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];
    
    if (action == @selector(tabViewAction:))
    {
		if ([[self tabView] indexOfSelectedTabViewItem] == [menuItem tag])
			[menuItem setState:NSOnState];
		else
			[menuItem setState:NSOffState];            
    }    
	
    return YES;
}

- (void)tabViewAction:(id)sender;
{
	int tag = [sender tag];
	
	[[self tabView] selectTabViewItemAtIndex:tag];
	
	[[NSUserDefaults standardUserDefaults] setInteger:tag forKey:[self prefKey]];
}

- (void)applyToFolderContentsAction:(id)sender;
{
	NSString* syncToBrowserID = [[self host] syncToBrowserID];
	NSArray* selection = [[self host] selection:[[self contentView] window] browserID:syncToBrowserID];
	if ([selection count])
	{
		NTFileDesc* directory = [selection objectAtIndex:0];
		
		if ([directory isDirectory])
			[[self host] applyDirectoriesAttributesToContents:(id<NTFSItem>)directory];
	}
}

@end

@implementation NTPermissionsUIController (nibObjects)

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
//  volumeView 
//---------------------------------------------------------- 
- (NSView *)volumeView
{
    return mVolumeView; 
}

- (void)setVolumeView:(NSView *)theVolumeView
{
    if (mVolumeView != theVolumeView)
    {
        [mVolumeView release];
		[mVolumeView release];  // top level nib object, must release twice
		
        mVolumeView = [theVolumeView retain];
    }
}

//---------------------------------------------------------- 
//  usersArrayController 
//---------------------------------------------------------- 
- (NSArrayController *)usersArrayController
{
    return mUsersArrayController; 
}

- (void)setUsersArrayController:(NSArrayController *)theUsersArrayController
{
    if (mUsersArrayController != theUsersArrayController)
    {
        [mUsersArrayController release];
        [mUsersArrayController release]; // top level nib object, must release twice
		
        mUsersArrayController = [theUsersArrayController retain];
    }
}

//---------------------------------------------------------- 
//  groupsArrayController 
//---------------------------------------------------------- 
- (NSArrayController *)groupsArrayController
{
    return mGroupsArrayController; 
}

- (void)setGroupsArrayController:(NSArrayController *)theGroupsArrayController
{
    if (mGroupsArrayController != theGroupsArrayController)
    {
        [mGroupsArrayController release];
		[mGroupsArrayController release]; // top level nib object, must release twice

        mGroupsArrayController = [theGroupsArrayController retain];
    }
}

@end

