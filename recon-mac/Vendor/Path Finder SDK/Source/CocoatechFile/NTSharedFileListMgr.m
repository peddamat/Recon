//
//  NTSharedFileListMgr.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 3/31/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTSharedFileListMgr.h"
#import "NTSharedFileListItem.h"
#import "NTIconStore.h"
#import "NTIcon.h"

static void callback(LSSharedFileListRef inList, void *context);

@interface NTSharedFileListMgr (Private)
- (NSArray*)itemsForList:(LSSharedFileListRef)theList; 
- (LSSharedFileListRef)createListRef:(NSString*)key;
- (void)releaseListRef:(LSSharedFileListRef)listRef;
- (void)notifyObservers:(NSString*)key;
- (NTSharedFileListItem*)loginItemForDesc:(NTFileDesc*)theDesc;
- (LSSharedFileListRef)listForID:(NSString*)listID;
- (NSString*)listIDForList:(LSSharedFileListRef)inList;

- (void)insertFile:(NTFileDesc*)theDesc atIndex:(NSUInteger)index listID:(NSString*)listID;
- (void)removeItemRef:(NTSharedFileListItem*)inItem listID:(NSString*)listID;
- (void)moveItemRef:(NTSharedFileListItem*)inItem atIndex:(NSUInteger)index listID:(NSString*)listID;
@end

@implementation NTSharedFileListMgr

@synthesize favoriteVolumes;
@synthesize favoriteFiles;
@synthesize recentApplications;
@synthesize recentDocuments;
@synthesize recentServers;
@synthesize notificationKeys;
@synthesize sentDelayedNotification;
@synthesize loginApplications;

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];
	
	// volumes
	self.favoriteVolumes = [self createListRef:(NSString*)kLSSharedFileListFavoriteVolumes];
	self.favoriteFiles = [self createListRef:(NSString*)kLSSharedFileListFavoriteItems];
	self.recentApplications = [self createListRef:(NSString*)kLSSharedFileListRecentApplicationItems];
	self.recentDocuments = [self createListRef:(NSString*)kLSSharedFileListRecentDocumentItems];
	self.recentServers = [self createListRef:(NSString*)kLSSharedFileListRecentServerItems];
	self.loginApplications = [self createListRef:(NSString*)kLSSharedFileListSessionLoginItems];
	
	self.notificationKeys = [NSMutableSet set];
	
	return self;
}

- (void)dealloc;
{
	[self releaseListRef:self.favoriteVolumes];
	self.favoriteVolumes = nil;
	
	[self releaseListRef:self.favoriteFiles];
	self.favoriteFiles = nil;
	
	[self releaseListRef:self.recentApplications];
	self.recentApplications = nil;
	
	[self releaseListRef:self.recentDocuments];
	self.recentDocuments = nil;
	
	[self releaseListRef:self.recentServers];
	self.recentServers = nil;
	
	[self releaseListRef:self.loginApplications];
	self.loginApplications = nil;
	
	self.notificationKeys = nil;
	
	[super dealloc];
}

- (NSArray*)favoriteFileItems; 
{
	return [self itemsForList:self.favoriteFiles];
}

- (NSArray*)favoriteVolumeItems; 
{
	return [self itemsForList:self.favoriteVolumes];
}

- (NSArray*)recentApplicationItems; 
{
	return [self itemsForList:self.recentApplications];
}

- (NSArray*)recentDocumentItems; 
{
	return [self itemsForList:self.recentDocuments];
}

- (NSArray*)recentServerItems; 
{
	return [self itemsForList:self.recentServers];
}

- (NSArray*)loginApplicationItems; 
{
	return [self itemsForList:self.loginApplications];
}

- (void)addLoginItem:(NTFileDesc*)theDesc;
{
	if ([theDesc isValid])
	{
		LSSharedFileListItemRef result = LSSharedFileListInsertItemFSRef(self.loginApplications,
																		 kLSSharedFileListItemLast,
																		 NULL,
																		 NULL,
																		 [theDesc FSRefPtr],
																		 NULL,
																		 NULL);
		
		if (result)
			CFRelease(result);	
	}
}

- (void)removeLoginItem:(NTFileDesc*)theDesc;
{
	NTSharedFileListItem* theItem = [self loginItemForDesc:theDesc];
	
	if (theItem)
		LSSharedFileListItemRemove(self.loginApplications, theItem.itemRef);	
}

- (BOOL)isLoginItem:(NTFileDesc*)theDesc;
{
	NTSharedFileListItem* theItem = [self loginItemForDesc:theDesc];
	
	return (theItem != nil);
}

- (void)removeAllRecentServers;
{
	LSSharedFileListRemoveAllItems(self.recentServers);
}

- (void)removeAllRecentDocuments;
{
	LSSharedFileListRemoveAllItems(self.recentDocuments);
}

- (void)removeAllRecentApplications;
{
	LSSharedFileListRemoveAllItems(self.recentApplications);
}

- (void)insertFavoriteFile:(NTFileDesc*)theDesc atIndex:(NSUInteger)index;
{	
	[self insertFile:theDesc atIndex:index listID:(NSString*)kLSSharedFileListFavoriteItems];
}

- (void)removeFavoriteItemRef:(NTSharedFileListItem*)inItem;
{
	[self removeItemRef:inItem listID:(NSString*)kLSSharedFileListFavoriteItems];
}

- (void)moveFavoriteItemRef:(NTSharedFileListItem*)inItem atIndex:(NSUInteger)index;
{
	[self moveItemRef:inItem atIndex:index listID:(NSString*)kLSSharedFileListFavoriteItems];
}

- (void)insertRecentFile:(NTFileDesc*)theDesc atIndex:(NSUInteger)index;
{	
	[self insertFile:theDesc atIndex:index listID:(NSString*)kLSSharedFileListRecentDocumentItems];
}

- (void)removeRecentItemRef:(NTSharedFileListItem*)inItem;
{
	[self removeItemRef:inItem listID:(NSString*)kLSSharedFileListRecentDocumentItems];
}

- (void)moveRecentItemRef:(NTSharedFileListItem*)inItem atIndex:(NSUInteger)index;
{
	[self moveItemRef:inItem atIndex:index listID:(NSString*)kLSSharedFileListRecentDocumentItems];
}

@end

@implementation NTSharedFileListMgr (Private)

- (NTSharedFileListItem*)loginItemForDesc:(NTFileDesc*)theDesc;
{
	NSURL* theURL = [theDesc URL];
	
	for (NTSharedFileListItem* theItem in [self loginApplicationItems])
	{
		if ([theItem.url isEqual:theURL])
			return theItem;
	}
	
	return nil;
}

- (NSArray*)itemsForList:(LSSharedFileListRef)theList; 
{
	NSMutableArray* result = [NSMutableArray array];
	
	if (theList)
	{
		UInt32 seed;
		CFArrayRef snapshot = LSSharedFileListCopySnapshot(theList,
														   &seed);
		
		if (snapshot)
		{
			for (id itemRef in (NSArray*)snapshot)
				[result addObject:[NTSharedFileListItem item:(LSSharedFileListItemRef)itemRef]];
			
			CFRelease(snapshot);
		}
	}
	
	return result;
}

- (LSSharedFileListRef)createListRef:(NSString*)key;
{
	LSSharedFileListRef result = LSSharedFileListCreate(kCFAllocatorDefault,
														(CFStringRef)key,
														NULL); 
	LSSharedFileListAddObserver(result,
								CFRunLoopGetMain(),
								kCFRunLoopDefaultMode,
								callback,
								self);	
	
	return result;
}

- (void)releaseListRef:(LSSharedFileListRef)listRef;
{
	if (listRef)
	{
		LSSharedFileListRemoveObserver(listRef,
									   CFRunLoopGetMain(),
									   kCFRunLoopDefaultMode,
									   callback,
									   self);
		
		CFRelease(listRef);
	}
}

// called on main thread
- (void)notifyObservers:(NSString*)key;
{
	if (!self.notificationKeys)
		self.notificationKeys = [NSMutableSet set];
	
	[self.notificationKeys addObject:key];
	
	if (!self.sentDelayedNotification)
	{
		self.sentDelayedNotification = YES;
		
		[self performDelayedSelector:@selector(notifyObserversAfterDelay) withObject:nil delay:.01];
	}
}

- (void)notifyObserversAfterDelay;
{
	self.sentDelayedNotification = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNTFileListsNotification 
														object:nil
													  userInfo:[NSDictionary dictionaryWithObject:self.notificationKeys forKey:@"keys"]];
	
	self.notificationKeys = nil;
}



- (void)insertFile:(NTFileDesc*)theDesc atIndex:(NSUInteger)index listID:(NSString*)listID;
{	
	LSSharedFileListRef theList = [self listForID:listID];
	NSArray* theListItems = [self itemsForList:theList];
	
	if (theList)
	{
		if ([theDesc isValid])
		{
			LSSharedFileListItemRef insertAfterItemRef=NULL;
			
			if (index == 0)
				insertAfterItemRef = kLSSharedFileListItemBeforeFirst;
			else
				insertAfterItemRef = ((NTSharedFileListItem*)[theListItems safeObjectAtIndex:index-1]).itemRef;
			
			if (insertAfterItemRef)
			{	
				LSSharedFileListItemRef result = LSSharedFileListInsertItemURL(theList,
																			   insertAfterItemRef,
																			   NULL,
																			   NULL,
																			   (CFURLRef)[theDesc URL],
																			   NULL,
																			   NULL);
				
				if (result)
					CFRelease(result);	
			}
		}
	}
}

- (void)removeItemRef:(NTSharedFileListItem*)inItem listID:(NSString*)listID;
{
	LSSharedFileListRef theList = [self listForID:listID];
	
	if (theList)
	{
		OSStatus err = LSSharedFileListItemRemove(theList, inItem.itemRef);
		
		if (err)
			NSLog(@"LSSharedFileListItemRemove err: %d", err);
	}
}

- (void)moveItemRef:(NTSharedFileListItem*)inItem atIndex:(NSUInteger)index listID:(NSString*)listID;
{
	LSSharedFileListRef theList = [self listForID:listID];
	NSArray* theListItems = [self itemsForList:theList];
	
	if (theList)
	{		
		LSSharedFileListItemRef moveAfterItemRef=NULL;
		
		if (index == 0)
			moveAfterItemRef = kLSSharedFileListItemBeforeFirst;
		else
		{			
			NSUInteger srcIndex = [theListItems indexOfObject:inItem]; 
			
			if ((srcIndex != NSNotFound) && (index < srcIndex))
				index--;
			
			NTSharedFileListItem* moveAfterItem = [theListItems safeObjectAtIndex:index];
			if (moveAfterItem)
			{
				// make sure they are not the same item
				if (![moveAfterItem isEqual:inItem])
					moveAfterItemRef = moveAfterItem.itemRef;
			}
		}
		
		if (inItem && moveAfterItemRef)
		{
			OSStatus err = LSSharedFileListItemMove(theList, inItem.itemRef, moveAfterItemRef);
			
			if (err)
				NSLog(@"LSSharedFileListItemMove err: %d", err);
		}
		else
			[self notifyObservers:listID];
	}
}

- (LSSharedFileListRef)listForID:(NSString*)listID;
{
	if ([listID isEqualToString:(NSString*)kLSSharedFileListFavoriteVolumes])
		return self.favoriteVolumes;
	else if ([listID isEqualToString:(NSString*)kLSSharedFileListFavoriteItems])
		return self.favoriteFiles;
	else if ([listID isEqualToString:(NSString*)kLSSharedFileListRecentApplicationItems])
		return self.recentApplications;
	else if ([listID isEqualToString:(NSString*)kLSSharedFileListRecentDocumentItems])
		return self.recentDocuments;
	else if ([listID isEqualToString:(NSString*)kLSSharedFileListRecentServerItems])
		return self.recentServers;
	else if ([listID isEqualToString:(NSString*)kLSSharedFileListSessionLoginItems])
		return self.loginApplications;
	
	return nil;
}

- (NSString*)listIDForList:(LSSharedFileListRef)inList;
{	
	if (inList == self.favoriteVolumes)
		return (NSString*)kLSSharedFileListFavoriteVolumes;
	else if (inList == self.favoriteFiles)
		return (NSString*)kLSSharedFileListFavoriteItems;
	else if (inList == self.recentApplications)
		return (NSString*)kLSSharedFileListRecentApplicationItems;
	else if (inList == self.recentDocuments)
		return (NSString*)kLSSharedFileListRecentDocumentItems;
	else if (inList == self.recentServers)
		return (NSString*)kLSSharedFileListRecentServerItems;
	else if (inList == self.loginApplications)
		return (NSString*)kLSSharedFileListSessionLoginItems;
	
	return nil;
}

@end

void callback(LSSharedFileListRef inList, void *context)
{
	NTSharedFileListMgr* seelf = (NTSharedFileListMgr*)context;
	NSString* key = [seelf listIDForList:inList];
	
	if (key)
		[seelf performSelectorOnMainThread:@selector(notifyObservers:) withObject:key];
}

@implementation NTSharedFileListMgr (Menus)

- (NSMenu*)recentDocumentsMenu:(NSMenu*)resultMenu;
{
	return [self recentDocumentsMenu:resultMenu fontSize:kDefaultMenuFontSize iconSize:kDefaultMenuIconSize clearItem:YES];
}

- (NSMenu*)recentDocumentsMenu:(NSMenu*)resultMenu fontSize:(int)fontSize iconSize:(int)iconSize clearItem:(BOOL)clearItem;
{    
    NSArray* theItems = [self recentDocumentItems];
	
	if (!resultMenu)
		resultMenu = [[[NSMenu alloc] init] autorelease];
	
	MENU_DISABLE(resultMenu);
	{
		NSMenuItem *menuItem;
		
		menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Recent Documents" table:@"menuBar"] action:0 keyEquivalent:@""] autorelease];
		[menuItem setFontSize:fontSize color:nil];
		[menuItem setEnabled:NO];
		
		[resultMenu addItem:menuItem];
		
		for (NTSharedFileListItem* theItem in theItems)
		{
			menuItem = [[[NSMenuItem alloc] initWithTitle:theItem.name action:@selector(recentDocumentsMenuAction:) keyEquivalent:@""] autorelease];
			[menuItem setTarget:self];
			[menuItem setFontSize:fontSize color:nil];
			[menuItem setRepresentedObject:theItem];
			
			// set icon
			NSImage* theIcon = [theItem iconWithSize:iconSize];
			if (!theIcon)
				theIcon = [[[NTIconStore sharedInstance] documentIcon] imageForSize:iconSize];
			[menuItem setImage:theIcon];
			
			[resultMenu addItem:menuItem];
		}
		
		// add clear menu
		if (clearItem)
		{
			[resultMenu addItem:[NSMenuItem separatorItem]];
			
			menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Clear Menu" table:@"menuBar"] action:@selector(clearRecentDocumentsMenuAction:) keyEquivalent:@""] autorelease];
			[menuItem setTarget:self];
			[menuItem setFontSize:fontSize color:nil];
			[menuItem setEnabled:([theItems count] != 0)];
			
			[resultMenu addItem:menuItem];
		}
	}
	MENU_ENABLE(resultMenu);
	
	return resultMenu;
}

- (NSMenu*)recentServersMenu:(NSMenu*)resultMenu;
{
	return [self recentServersMenu:resultMenu
						  fontSize:kDefaultMenuFontSize 
						  iconSize:kDefaultMenuIconSize 
						 clearItem:YES];	
}

- (NSMenu*)recentServersMenu:(NSMenu*)resultMenu
					fontSize:(int)fontSize 
					iconSize:(int)iconSize 
				   clearItem:(BOOL)clearItem;
{
	return [self recentServersMenu:resultMenu
						  fontSize:fontSize 
						  iconSize:iconSize 
					  customAction:nil
					  customTarget:nil
						 clearItem:YES];
}

- (NSMenu*)recentServersMenu:(NSMenu*)resultMenu
					fontSize:(int)fontSize 
					iconSize:(int)iconSize 
				customAction:(SEL)customAction
				customTarget:(id)customTarget
				   clearItem:(BOOL)clearItem;
{    
    NSArray* theItems = [self recentServerItems];
	
	if (!resultMenu)
		resultMenu = [[[NSMenu alloc] init] autorelease];
	
	MENU_DISABLE(resultMenu);
	{
		NSMenuItem *menuItem;
		id theTarget = customTarget;
		SEL theAction = customAction;
		
		if (!theAction)
		{
			theTarget = self;
			theAction = @selector(recentServerMenuAction:);
		}
		
		menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Recent Servers" table:@"menuBar"] action:0 keyEquivalent:@""] autorelease];
		[menuItem setFontSize:fontSize color:nil];
		[menuItem setEnabled:NO];
		
		[resultMenu addItem:menuItem];
		
		for (NTSharedFileListItem* theItem in theItems)
		{
			menuItem = [[[NSMenuItem alloc] initWithTitle:theItem.name action:theAction keyEquivalent:@""] autorelease];
			[menuItem setTarget:theTarget];
			[menuItem setFontSize:fontSize color:nil];
			[menuItem setRepresentedObject:theItem];
			
			// set icon
			NSImage* theIcon = [theItem iconWithSize:iconSize];
			if (!theIcon)
				theIcon = [[[NTIconStore sharedInstance] fileServerIcon] imageForSize:iconSize];
			[menuItem setImage:theIcon];
			
			[resultMenu addItem:menuItem];
		}
		
		// add clear menu
		if (clearItem)
		{
			[resultMenu addItem:[NSMenuItem separatorItem]];
			
			menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Clear Menu" table:@"menuBar"] action:@selector(clearRecentServerMenuAction:) keyEquivalent:@""] autorelease];
			[menuItem setTarget:self];
			[menuItem setFontSize:fontSize color:nil];
			[menuItem setEnabled:([theItems count] != 0)];
			
			[resultMenu addItem:menuItem];
		}
	}
	MENU_ENABLE(resultMenu);
	
	return resultMenu;
}

- (NSMenu*)recentApplicationsMenu:(NSMenu*)resultMenu;
{
	return [self recentApplicationsMenu:resultMenu fontSize:kDefaultMenuFontSize iconSize:kDefaultMenuIconSize clearItem:YES];
}

- (NSMenu*)recentApplicationsMenu:(NSMenu*)resultMenu fontSize:(int)fontSize iconSize:(int)iconSize clearItem:(BOOL)clearItem;
{    
    NSArray* theItems = [self recentApplicationItems];
	
	if (!resultMenu)
		resultMenu = [[[NSMenu alloc] init] autorelease];
	
	MENU_DISABLE(resultMenu);
	{
		NSMenuItem *menuItem;
		
		menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Recent Applications" table:@"menuBar"] action:0 keyEquivalent:@""] autorelease];
		[menuItem setFontSize:fontSize color:nil];
		[menuItem setEnabled:NO];
		
		[resultMenu addItem:menuItem];
		
		for (NTSharedFileListItem* theItem in theItems)
		{
			menuItem = [[[NSMenuItem alloc] initWithTitle:theItem.name action:@selector(recentApplicationsMenuAction:) keyEquivalent:@""] autorelease];
			[menuItem setTarget:self];
			[menuItem setFontSize:fontSize color:nil];
			[menuItem setRepresentedObject:theItem];
			
			// set icon
			NSImage* theIcon = [theItem iconWithSize:iconSize];
			if (!theIcon)
				theIcon = [[[NTIconStore sharedInstance] fileServerIcon] imageForSize:iconSize];
			[menuItem setImage:theIcon];
			
			[resultMenu addItem:menuItem];
		}
		
		// add clear menu
		if (clearItem)
		{
			[resultMenu addItem:[NSMenuItem separatorItem]];
			
			menuItem = [[[NSMenuItem alloc] initWithTitle:[NTLocalizedString localize:@"Clear Menu" table:@"menuBar"] action:@selector(clearRecentApplicationsMenuAction:) keyEquivalent:@""] autorelease];
			[menuItem setTarget:self];
			[menuItem setFontSize:fontSize color:nil];
			[menuItem setEnabled:([theItems count] != 0)];
			
			[resultMenu addItem:menuItem];
		}
	}
	MENU_ENABLE(resultMenu);
	
	return resultMenu;
}

- (void)clearRecentServerMenuAction:(NSMenuItem*)theMenuItem;
{
	[self removeAllRecentServers];
}

- (void)recentServerMenuAction:(NSMenuItem*)theMenuItem;
{
	NTSharedFileListItem* theItem = [theMenuItem representedObject];
	
	[theItem resolvedURL];  // mounts the share
}

- (void)clearRecentDocumentsMenuAction:(NSMenuItem*)theMenuItem;
{
	[self removeAllRecentDocuments];
}

- (void)recentDocumentsMenuAction:(NSMenuItem*)theMenuItem;
{
	NTSharedFileListItem* theItem = [theMenuItem representedObject];
	
	NSURL* url = [theItem resolvedURL];  // mounts the disk if needed
	
	NTFileDesc *desc = [NTFileDesc descResolve:[url path]];
	
	if ([desc isValid])
		[[NTDoubleClickHandler sharedInstance] handleDoubleClick:desc startRect:NSZeroRect window:nil params:[NTRevealParameters params:NO other:nil]];
	else
		NSBeep();
}

- (void)clearRecentApplicationsMenuAction:(NSMenuItem*)theMenuItem;
{
	[self removeAllRecentApplications];
}

- (void)recentApplicationsMenuAction:(NSMenuItem*)theMenuItem;
{
	NTSharedFileListItem* theItem = [theMenuItem representedObject];
	
	NSURL* url = [theItem resolvedURL];  // mounts the disk if needed
	
	NTFileDesc *desc = [NTFileDesc descResolve:[url path]];
	
	if ([desc isValid])
		[[NTDoubleClickHandler sharedInstance] handleDoubleClick:desc startRect:NSZeroRect window:nil params:[NTRevealParameters params:NO other:nil]];
	else
		NSBeep();
}

@end
