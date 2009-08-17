//
//  NTiTunesUIController.m
//  iTunesModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTiTunesUIController.h"
#import "NTITunesDataModel.h"
#import "NTMenuPluginProtocol.h"
#import "GBUtilities.h"

// =====================================================================================

@interface NTiTunesUIModel : NSObject
{
	NSMutableDictionary* dict;
	id<NTPathFinderPluginHostProtocol> host;
}
+ (NTiTunesUIModel*)model:(id<NTPathFinderPluginHostProtocol>)host;

@property (retain) NSMutableDictionary* dict;
@property (retain) id<NTPathFinderPluginHostProtocol> host;

- (id)valueForKey:(NSString*)key;
- (void)setValue:(id)value forKey:(NSString *)key;

@end

// =====================================================================================

@interface NTiTunesUIController (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTiTunesUIController (nibObjects)
- (NSView *)contentView;
- (void)setContentView:(NSView *)theContentView;

- (NSView *)leftView;
- (void)setLeftView:(NSView *)theLeftView;

- (NSView *)rightView;
- (void)setRightView:(NSView *)theRightView;

- (NSView *)toolbarView;
- (void)setToolbarView:(NSView *)theToolbarView;

- (NSObjectController *)objectController;
- (void)setObjectController:(NSObjectController *)theObjectController;

- (NSObjectController *)UIModelObjectController;
- (void)setUIModelObjectController:(NSObjectController *)theObjectController;

- (NSArrayController *)tracksArrayController;
- (void)setTracksArrayController:(NSArrayController *)theTracksArrayController;

- (NSArrayController *)artistsArrayController;
- (void)setArtistsArrayController:(NSArrayController *)theArtistsArrayController;

- (NSArrayController *)listTypeArrayController;
- (void)setListTypeArrayController:(NSArrayController *)theArrayController;
@end

@interface NTiTunesUIController (Private)
- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;

- (int)toolbarHeight;
- (void)setToolbarHeight:(int)theToolbarHeight;

- (NTITunesDataModel *)model;
- (void)setModel:(NTITunesDataModel *)theModel;

- (NSArray*)pathsForIndexes:(NSIndexSet*)indexSet;

- (void)contentFrameDidChange:(NSNotification*)notification;
- (void)repositionViews;

@end

@implementation NTiTunesUIController

@synthesize splitView;
@synthesize splitViewDelegate;
@synthesize haveSetupSplitview;
@synthesize UIModel;

+ (NTiTunesUIController*)controller:(id<NTPathFinderPluginHostProtocol>)host;
{
	NTiTunesUIController* result = [[NTiTunesUIController alloc] init];
	
	[result setHost:host];
	
	result.UIModel = [NTiTunesUIModel model:host];
	
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    [self setView:nil];
    [self setObjectController:nil];
	[self setUIModelObjectController:nil];
	[self setTracksArrayController:nil];
    [self setArtistsArrayController:nil];
    [self setListTypeArrayController:nil];
    [self setHost:nil];

	[self setModel:nil];
    [self setContentView:nil];
    [self setLeftView:nil];
    [self setRightView:nil];
    [self setToolbarView:nil];
	
	[self.splitViewDelegate clearDelegate];
	self.splitViewDelegate = nil;
	self.splitView = nil;
	self.UIModel = nil;
	
    [super dealloc];
}

- (void)awakeFromNib;
{
}

//---------------------------------------------------------- 
//  view 
//---------------------------------------------------------- 
- (NSView *)view
{
	if (!mView)
	{
		// build our view
		// create NSSplitView, add right and left views
		self.splitView = [[[NSSplitView alloc] initWithFrame:NSZeroRect] autorelease];
		[self.splitView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
		[self.splitView setDividerStyle:NSSplitViewDividerStyleThin];
		
		self.splitViewDelegate = [NTSplitViewDelegate splitViewDelegate];
		self.splitViewDelegate.collapseViewIndex = -1;  // don't allow collapsing
		[self.splitView setDelegate:self.splitViewDelegate];
		[self.splitView setVertical:YES];
		
		[self.splitView addSubview:[self leftView]];
		[self.splitView addSubview:[self rightView]];
		
		[[self contentView] addSubview:[self toolbarView]];
		[[self contentView] addSubview:self.splitView];
		
		[self setView:[self contentView]];
		
		[self repositionViews];
				
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentFrameDidChange:) name:NSViewFrameDidChangeNotification object:[self contentView]];
	}
	
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
	[[self UIModelObjectController] unbind:@"contentObject"];
	[[self objectController] unbind:@"contentObject"];
}

@end

@implementation NTiTunesUIController (Private)

- (void)contentFrameDidChange:(NSNotification*)notification;
{
	[self repositionViews];
}

- (void)repositionViews;
{
	NSRect toolbarRect, splitViewFrame;

	const int height = 26;

	NSDivideRect([[self contentView] bounds], &toolbarRect, &splitViewFrame, height, NSMinYEdge);
	
	toolbarRect.origin.y += (height - [self toolbarHeight]) / 2;
		
	[self.splitView setFrame:NSInsetRect(splitViewFrame, -1, 0)];
	[[self toolbarView] setFrame:toolbarRect];
	
	if ([[self contentView] window] && !self.haveSetupSplitview)
	{
		self.haveSetupSplitview = YES;
		[self.splitView setupSplitView:NSStringFromClass([self class]) defaultFraction:.25];
	}
}

//---------------------------------------------------------- 
//  model 
//---------------------------------------------------------- 
- (NTITunesDataModel *)model
{
	if (!mModel)
		[self setModel:[NTITunesDataModel model]];

    return mModel; 
}

- (void)setModel:(NTITunesDataModel *)theModel
{
    if (mModel != theModel)
    {
        [mModel release];
        mModel = [theModel retain];
    }
}

- (NSArray*)pathsForIndexes:(NSIndexSet*)indexSet;
{
	NSUInteger index = [indexSet firstIndex];
	NSArray *arr = [[self tracksArrayController] arrangedObjects];
	NSMutableArray* result = [NSMutableArray array];
	
	while (index != NSNotFound)
	{
		NSDictionary* dict = [arr objectAtIndex:index];
		
		NSString* path = [dict objectForKey:@"path"];
		
		if (path)
			[result addObject:path];
		
		index = [indexSet indexGreaterThanIndex:index];
	}
	
	return result;
}

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
//  toolbarHeight 
//---------------------------------------------------------- 
- (int)toolbarHeight
{
    return mToolbarHeight;
}

- (void)setToolbarHeight:(int)theToolbarHeight
{
    mToolbarHeight = theToolbarHeight;
}

@end

@implementation NTiTunesUIController (nibObjects)

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
//  leftView 
//---------------------------------------------------------- 
- (NSView *)leftView
{
    return mLeftView; 
}

- (void)setLeftView:(NSView *)theLeftView
{
    if (mLeftView != theLeftView)
    {
        [mLeftView release];
        [mLeftView release];  // top level nib object, must release twice
        mLeftView = [theLeftView retain];
    }
}

//---------------------------------------------------------- 
//  rightView 
//---------------------------------------------------------- 
- (NSView *)rightView
{
    return mRightView; 
}

- (void)setRightView:(NSView *)theRightView
{
    if (mRightView != theRightView)
    {
        [mRightView release];
        [mRightView release];  // top level nib object, must release twice
        mRightView = [theRightView retain];
    }
}

//---------------------------------------------------------- 
//  toolbarView 
//---------------------------------------------------------- 
- (NSView *)toolbarView
{
    return mToolbarView; 
}

- (void)setToolbarView:(NSView *)theToolbarView
{
    if (mToolbarView != theToolbarView)
    {
        [mToolbarView release];
        [mToolbarView release];  // top level nib object, must release twice
        mToolbarView = [theToolbarView retain];
		
		if (mToolbarView)
			[self setToolbarHeight:[mToolbarView frame].size.height];
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
        [mObjectController release]; // top level nib object, must release twice
		
        mObjectController = [theObjectController retain];
    }
}

//---------------------------------------------------------- 
//  UIModelObjectController 
//---------------------------------------------------------- 
- (NSObjectController *)UIModelObjectController
{
    return UIModelObjectController; 
}

- (void)setUIModelObjectController:(NSObjectController *)theObjectController
{
    if (UIModelObjectController != theObjectController)
    {
        [UIModelObjectController release];
        [UIModelObjectController release]; // top level nib object, must release twice
		
        UIModelObjectController = [theObjectController retain];
    }
}

//---------------------------------------------------------- 
//  tracksArrayController 
//---------------------------------------------------------- 
- (NSArrayController *)tracksArrayController
{
    return mTracksArrayController; 
}

- (void)setTracksArrayController:(NSArrayController *)theTracksArrayController
{
    if (mTracksArrayController != theTracksArrayController)
    {
        [mTracksArrayController release];
        [mTracksArrayController release];
        mTracksArrayController = [theTracksArrayController retain];
    }
}

//---------------------------------------------------------- 
//  artistsArrayController 
//---------------------------------------------------------- 
- (NSArrayController *)artistsArrayController
{
    return mArtistsArrayController; 
}

- (void)setArtistsArrayController:(NSArrayController *)theArtistsArrayController
{
    if (mArtistsArrayController != theArtistsArrayController)
    {
        [mArtistsArrayController release];
        [mArtistsArrayController release];
        mArtistsArrayController = [theArtistsArrayController retain];
    }
}

//---------------------------------------------------------- 
//  listTypeArrayController 
//---------------------------------------------------------- 
- (NSArrayController *)listTypeArrayController
{
    return mListTypeArrayController; 
}

- (void)setListTypeArrayController:(NSArrayController *)theArrayController
{
    if (mListTypeArrayController != theArrayController)
    {
        [mListTypeArrayController release];
        [mListTypeArrayController release];
        mListTypeArrayController = [theArrayController retain];
    }
}

@end

@implementation NTiTunesUIController (NSTableViewDelegate)

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard;
{
    // Copy the row numbers to the pasteboard.
    NSArray* paths = [self pathsForIndexes:rowIndexes];
    
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
	[pboard setPropertyList:paths forType:NSFilenamesPboardType];

    return YES;
}

@end

// =====================================================================================

@implementation NTiTunesUIModel

@synthesize host, dict;

+ (NTiTunesUIModel*)model:(id<NTPathFinderPluginHostProtocol>)theHost;
{
	NTiTunesUIModel* result = [[NTiTunesUIModel alloc] init];

	result.host = theHost;
	result.dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					  [[result host] iconForType:kGenericWindowIcon size:24], @"revealIcon",
					  [[result host] iconForType:kBurningIcon size:24], @"burnIcon",
					  @"Reveal", @"revealToolTip",
					  @"Burn", @"burnToolTip",
					  nil];
	
	return [result autorelease];
}

- (void)dealloc;
{
	self.dict = nil;
	self.host = nil;
	
	[super dealloc];
}

- (id)valueForKey:(NSString*)key;
{
	return [self.dict valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key;
{
	[self.dict setValue:value forKey:key];
}

@end

@implementation NTiTunesUIModel (Actions)

- (NSArray*)selectedPaths:(NSArray*)selectedObjects;
{
	NSMutableArray* result = [NSMutableArray array];
	for (NSDictionary* item in selectedObjects)
	{
		NSString* path = [item objectForKey:@"path"];
		
		if (path)
			[result addObject:path];
	}
	
	return result;
}

- (void)revealButtonAction:(id)sender;
{
	NSArray* selection = [self selectedPaths:sender];
	
	if ([selection count])
	{
		NSArray* items = [[self host] newFSItems:selection];
		
		if ([items count])
			[[self host] revealItem:[items objectAtIndex:0] window:nil browserID:nil];
	}	
}

- (void)burnButtonAction:(id)sender;
{	
	NSArray* selection = [self selectedPaths:sender];
	
	if ([selection count])
	{
		NSArray* items = [[self host] newFSItems:selection];
		
		if ([items count])
		{
			NSMutableDictionary *parameter = [NSMutableDictionary dictionary];
			
			[parameter setObject:[NSNumber numberWithInt:4/*kAudioFileSystem*/] forKey:@"format"];
			if ([[self host] sheetWindow:nil])
				[parameter setObject:[[self host] sheetWindow:nil] forKey:@"window"];
			
			[[self host] processItems:items 
							parameter:parameter
							 pluginID:kNTPluginIdentifier_burnMenu];
		}
	}
}

- (void)tableDoubleClickAction:(NSArray*)selectedObjects;
{
	// dictionaries with a "path" key/object
	NSDictionary* theDict;
	
	for (theDict in selectedObjects)
		[[NSWorkspace sharedWorkspace] openFile:[theDict objectForKey:@"path"]];
}

@end

