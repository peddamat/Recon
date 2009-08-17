//
//  NTAttributeUIController.m
//  AttributeModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTAttributeUIController.h"
#import "NTAttributeUIModel.h"
#import "NTModulePluginProtocol.h"
#import "NTAttributeUIModelThread.h"

@interface NTAttributeUIController (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTAttributeUIController (nibObjects)
- (NSObjectController *)objectController;
- (void)setObjectController:(NSObjectController *)theObjectController;

- (NSView *)datesView;
- (void)setDatesView:(NSView *)theDatesView;

- (NSView *)contentView;
- (void)setContentView:(NSView *)theContentView;
@end

@interface NTAttributeUIController (Private)
- (NSView*)createView;
- (NSString*)prefKey;

- (NTThreadRunner *)threadRunner;
- (void)setThreadRunner:(NTThreadRunner *)theThreadRunner;

- (NSTabView *)tabView;
- (void)setTabView:(NSTabView *)theTabView;

- (NTAttributeUIModel *)model;
- (void)setModel:(NTAttributeUIModel *)theModel;
@end

@interface NTAttributeUIController (Protocols) <NTThreadRunnerDelegateProtocol>
@end

@implementation NTAttributeUIController

@synthesize host;

+ (NTAttributeUIController*)controller:(id<NTPathFinderPluginHostProtocol>)theHost;
{
	NTAttributeUIController* result = [[NTAttributeUIController alloc] init];
	
	[result setHost:theHost];
		
	// a valid model must always be present since this gives the contents of the matrix of labels
	[result setModel:[NTAttributeUIModel model]];

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
    [self setDatesView:nil];
	[self setThreadRunner:nil];
    [self setHost:nil];
	[self setTabView:nil];
	
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
		[self setThreadRunner:[NTAttributeUIModelThread thread:items delegate:self]];
	}
	else
		[self setModel:nil];
}

- (NSMenu*)menu;
{
	NSMenu* menu = [[NSMenu alloc] init];
	NSMenuItem* menuItem;
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Attributes" table:@"Get Info"] action:@selector(tabViewAction:) keyEquivalent:@""] autorelease];
	[menuItem setFontSize:kSmallMenuFontSize color:nil];
    [menuItem setTarget:self];
	[menuItem setTag:0];
    [menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Dates/Forks" table:@"Get Info"] action:@selector(tabViewAction:) keyEquivalent:@""] autorelease];
	[menuItem setFontSize:kSmallMenuFontSize color:nil];
	[menuItem setTarget:self];
    [menuItem setTag:1];
    [menu addItem:menuItem];
		
	return [menu autorelease];
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

- (NTFileDesc*)selectedItem;
{
	NSArray *selection = [self selection];
	
	if ([selection count])
		return [selection objectAtIndex:0];
	
	return nil;
}

@end

@implementation NTAttributeUIController (Protocols)

// NTThreadRunnerDelegateProtocol
- (void)threadRunner_complete:(NTThreadRunner*)threadRunner;
{
	if (threadRunner == [self threadRunner])
	{
		NTAttributeUIModelThread* param = (NTAttributeUIModelThread*)[threadRunner param];
		
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

@implementation NTAttributeUIController (Private)

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
	
    tab = [[[NSTabViewItem alloc] initWithIdentifier:@"dates"] autorelease];
    [tab setLabel:[NTLocalizedString localize:@"Dates"]];
    [tab setView:[self datesView]];
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

- (NSString*)prefKey;
{
	return [NSString stringWithFormat:@"%@:%@:selectedTabIndex", [[self host] modulePrefKey], NSStringFromClass([self class])];
}

//---------------------------------------------------------- 
//  model 
//---------------------------------------------------------- 
- (NTAttributeUIModel *)model
{	
    return mModel; 
}

- (void)setModel:(NTAttributeUIModel *)theModel
{
    if (mModel != theModel)
    {
		[mModel stopObserving:self];
		
        [mModel release];
        mModel = [theModel retain];
    }
}

- (void)observeValueForKeyPath:(NSString *)key
					  ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context;
{	
	NTFileDesc* selectedItem = [self selectedItem];
		
	// must have a selection
	if (selectedItem)
	{
		NSArray* selection = [self selection];
		
		if ([[self model] initialized])
		{
			if ([key isEqualToString:@"name"])
				[[self host] rename:(id<NTFSItem>)selectedItem withName:[[self model] name]];
			else if ([key isEqualToString:@"selectedLabels"])
			{
				NSArray* labels = [[self model] selectedLabels];
				
				if ([labels count])
					[[self host] set:[labels objectAtIndex:0] attributeID:kLabel_attributeID items:selection];
			}
			else if ([key isEqualToString:@"locked"])
				[[self host] set:[NSNumber numberWithBool:[[self model] locked]] attributeID:kLocked_attributeID items:selection];
			else if ([key isEqualToString:@"invisible"])
				[[self host] set:[NSNumber numberWithBool:[[self model] invisible]] attributeID:kInvisible_attributeID items:selection];															
			else if ([key isEqualToString:@"hideExtension"])
				[[self host] set:[NSNumber numberWithBool:[[self model] hideExtension]] attributeID:kExtensionHidden_attributeID items:selection];												
			else if ([key isEqualToString:@"stationeryPad"])
				[[self host] set:[NSNumber numberWithBool:[[self model] stationeryPad]] attributeID:kStationeryPad_attributeID items:selection];									
			else if ([key isEqualToString:@"bundleBit"])
				[[self host] set:[NSNumber numberWithBool:[[self model] bundleBit]] attributeID:kHasBundle_attributeID items:selection];						
			else if ([key isEqualToString:@"aliasBit"])				
				[[self host] set:[NSNumber numberWithBool:[[self model] aliasBit]] attributeID:kAlias_attributeID items:selection];
			else if ([key isEqualToString:@"customIcon"])
				[[self host] set:[NSNumber numberWithBool:[[self model] customIcon]] attributeID:kCustomIcon_attributeID items:selection];			
			else if ([key isEqualToString:@"type"])
				[[self host] set:[NSNumber numberWithUnsignedInt:[NTUtilities stringToInt:[[self model] type]]] attributeID:kType_attributeID items:selection];			
			else if ([key isEqualToString:@"creator"])
				[[self host] set:[NSNumber numberWithUnsignedInt:[NTUtilities stringToInt:[[self model] creator]]] attributeID:kCreator_attributeID items:selection];			
			else if ([key isEqualToString:@"spotlightComments"])
				[[self host] set:[[self model] spotlightComments] attributeID:kSpotlightComments_attributeID items:selection];			
			
			else if ([key isEqualToString:@"creationDate"])
				[[self host] set:[[self model] creationDate] attributeID:kCreationDate_attributeID items:selection];			
			else if ([key isEqualToString:@"modificationDate"])
				[[self host] set:[[self model] modificationDate] attributeID:kModificationDate_attributeID items:selection];			
		}
	}
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

// called from sheet
- (IBAction)doDeleteDataForkAction:(id)sender;
{
    NTAlertPanel* panel = (NTAlertPanel*)sender;
    
    if ([panel resultCode] == NSAlertFirstButtonReturn)
        [NTFileDesc deleteDataFork:[self selectedItem]];
}

// called from the sheet
- (IBAction)doDeleteResourceForkAction:(id)sender;
{
    NTAlertPanel* panel = (NTAlertPanel*)sender;
    
    if ([panel resultCode] == NSAlertFirstButtonReturn)
        [NTFileDesc deleteResourceFork:[self selectedItem]];
}

- (IBAction)doSwapForksActions:(id)sender;
{
    NTAlertPanel* panel = (NTAlertPanel*)sender;
    
    if ([panel resultCode] == NSAlertFirstButtonReturn)
    {        
        unsigned long long rsrcSize, dataSize;
        
        dataSize = [[self selectedItem] dataForkSize];
        rsrcSize = [[self selectedItem] rsrcForkSize];
        
        // if both forks are non-empty, write rsrc fork to temp file, move data to rsrc fork, copy from temp to data
        if (rsrcSize != 0 && dataSize != 0)
        {
            NSString* destPath = [[NTFileNamingManager sharedInstance] uniqueName:[[[NTDefaultDirectory sharedInstance] tmpPath] stringByAppendingPathComponent:@"temp"] with:nil];
            
			// copy to temp folder
			[[NSFileManager defaultManager] copyItemAtPath:[[self selectedItem] path] toPath:destPath error:nil];
				
			// did the copy succeed?
			NTFileDesc* tempDesc = [NTFileDesc descNoResolve:destPath];
			if ([tempDesc isValid])
            {
                // do the swap
                [NTFileDesc copy:tempDesc fromDataFork:NO to:[self selectedItem] toDataFork:YES];
                [NTFileDesc copy:tempDesc fromDataFork:YES to:[self selectedItem] toDataFork:NO];
                
                // delete temp file
				FSDeleteObject([tempDesc FSRefPtr]);
            }
        }
        else
        {
            if (dataSize != 0)
            {
                // move data fork to resource fork
                [NTFileDesc copy:[self selectedItem] fromDataFork:YES to:[self selectedItem] toDataFork:NO];
                
                // empty out data fork
                [NTFileDesc deleteDataFork:[self selectedItem]];
            }
            else
            {
                // move resource fork to data fork fork
                [NTFileDesc copy:[self selectedItem] fromDataFork:NO to:[self selectedItem] toDataFork:YES];
                
                // empty out resource fork
                [NTFileDesc deleteResourceFork:[self selectedItem]];
            }
        }
    }
}

@end

@implementation NTAttributeUIController (Actions)

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

- (IBAction)deleteRsrcForkAction:(id)sender;
{
    if ([[self selectedItem] rsrcForkSize] > 0)
    {
        [NTAlertPanel show:NSCriticalAlertStyle
					target:self
				  selector:@selector(doDeleteResourceForkAction:)
					 title:[NTLocalizedString localize:@"Alert!" table:@"Get Info"]
				   message:[NTLocalizedString localize:@"Deleting the resource fork is not undoable.  Are you sure you want to delete this data?" table:@"Get Info"]
				   context:nil
					window:[[self host] sheetWindow:[[self view] window]]];
    }
}

- (IBAction)deleteDataForkAction:(id)sender;
{
	if ([[self selectedItem] dataForkSize] > 0)
    {
		[NTAlertPanel show:NSCriticalAlertStyle
					target:self
				  selector:@selector(doDeleteDataForkAction:)
					 title:[NTLocalizedString localize:@"Alert!" table:@"Get Info"]
				   message:[NTLocalizedString localize:@"Deleting the data fork is not undoable.  Are you sure you want to delete this data?" table:@"Get Info"]
				   context:nil
					window:[[self host] sheetWindow:[[self view] window]]];
	}
}
	
- (IBAction)swapForksAction:(id)sender;
{
	[NTAlertPanel show:NSCriticalAlertStyle
				target:self
			  selector:@selector(doSwapForksActions:)
				 title:[NTLocalizedString localize:@"Alert!" table:@"Get Info"]
			   message:[NTLocalizedString localize:@"Swapping forks can be undone by swapping again.  Are you sure you want to swap the forks?" table:@"Get Info"]
			   context:nil
				window:[[self host] sheetWindow:[[self view] window]]];
}

/*
 {
	 unsigned long long rsrcSize, dataSize;
	 
	 dataSize = [[self selectedItem] dataForkSize];
	 rsrcSize = [[self selectedItem] rsrcForkSize];
	 
	 if (dataSize > 0)
		 [deleteDataForkButton setEnabled:YES];
	 else
		 [deleteDataForkButton setEnabled:NO];
	 
	 if (rsrcSize > 0)
		 [deleteRsrcForkButton setEnabled:YES];
	 else
		 [deleteRsrcForkButton setEnabled:NO];
	 
	 if ((rsrcSize > 0) || (dataSize > 0))
		 [swapForksButton setEnabled:YES];
	 else
		 [swapForksButton setEnabled:NO];
 }
 
 */ 

@end

@implementation NTAttributeUIController (nibObjects)

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
//  datesView 
//---------------------------------------------------------- 
- (NSView *)datesView
{
    return mDatesView; 
}

- (void)setDatesView:(NSView *)theDatesView
{
    if (mDatesView != theDatesView)
    {
        [mDatesView release];
		[mDatesView release];  // top level nib object, must release twice
		
        mDatesView = [theDatesView retain];
    }
}

@end

