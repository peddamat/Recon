//
//  NTSharedFileListMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 3/31/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTSharedFileListItem;

// userInfo contains @"keys" which is an NSSet of keys that updated.  ie: kLSSharedFileListFavoriteVolumes
#define kNTFileListsNotification @"NTFileListsNotification"

@interface NTSharedFileListMgr : NTSingletonObject 
{
	LSSharedFileListRef favoriteVolumes;
	LSSharedFileListRef favoriteFiles;
	LSSharedFileListRef recentApplications;
	LSSharedFileListRef recentDocuments;
	LSSharedFileListRef recentServers;
	LSSharedFileListRef loginApplications;
	
	NSMutableSet* notificationKeys;
	BOOL sentDelayedNotification;
}

@property (assign) LSSharedFileListRef favoriteVolumes;
@property (assign) LSSharedFileListRef favoriteFiles;
@property (assign) LSSharedFileListRef recentApplications;
@property (assign) LSSharedFileListRef recentDocuments;
@property (assign) LSSharedFileListRef recentServers;
@property (assign) LSSharedFileListRef loginApplications;

@property (retain) NSMutableSet* notificationKeys;
@property (assign) BOOL sentDelayedNotification;

- (NSArray*)favoriteFileItems; 
- (NSArray*)favoriteVolumeItems; 
- (NSArray*)recentApplicationItems; 
- (NSArray*)recentDocumentItems; 
- (NSArray*)recentServerItems; 
- (NSArray*)loginApplicationItems; 

- (void)removeAllRecentServers;
- (void)removeAllRecentDocuments;
- (void)removeAllRecentApplications;

- (void)addLoginItem:(NTFileDesc*)theDesc;
- (void)removeLoginItem:(NTFileDesc*)theDesc;
- (BOOL)isLoginItem:(NTFileDesc*)theDesc;

// places
- (void)insertFavoriteFile:(NTFileDesc*)theDesc atIndex:(NSUInteger)index;
- (void)removeFavoriteItemRef:(NTSharedFileListItem*)inItem;
- (void)moveFavoriteItemRef:(NTSharedFileListItem*)inItem atIndex:(NSUInteger)index;

// recent documents
- (void)insertRecentFile:(NTFileDesc*)theDesc atIndex:(NSUInteger)index;
- (void)removeRecentItemRef:(NTSharedFileListItem*)inItem;
- (void)moveRecentItemRef:(NTSharedFileListItem*)inItem atIndex:(NSUInteger)index;
@end

@interface NTSharedFileListMgr (Menus)
- (NSMenu*)recentServersMenu:(NSMenu*)resultMenu;
- (NSMenu*)recentServersMenu:(NSMenu*)resultMenu
					fontSize:(int)fontSize 
					iconSize:(int)iconSize 
				   clearItem:(BOOL)clearItem;
- (NSMenu*)recentServersMenu:(NSMenu*)resultMenu
					fontSize:(int)fontSize 
					iconSize:(int)iconSize 
				customAction:(SEL)customAction
				customTarget:(id)customTarget
				   clearItem:(BOOL)clearItem;

- (NSMenu*)recentDocumentsMenu:(NSMenu*)resultMenu;
- (NSMenu*)recentDocumentsMenu:(NSMenu*)resultMenu fontSize:(int)fontSize iconSize:(int)iconSize clearItem:(BOOL)clearItem;

- (NSMenu*)recentApplicationsMenu:(NSMenu*)resultMenu;
- (NSMenu*)recentApplicationsMenu:(NSMenu*)resultMenu fontSize:(int)fontSize iconSize:(int)iconSize clearItem:(BOOL)clearItem;
@end
