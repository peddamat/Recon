//
//  NTIconStore.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Thu Aug 15 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTIcon;

@interface NTIconStore : NTSingletonObject
{
	NSBundle* coreTypesBundle;
	NSMutableDictionary* icons;
	NSMutableDictionary* systemIcons;
	
	NSImage* miniFile;
	NSImage* miniFolder;
	NSImage* miniApplication;
	NSImage* countBadgeImage;
	NSImage* countBadgeImage3;
	NSImage* countBadgeImage4;
	NSImage* countBadgeImage5;
}

@property (retain) NSBundle* coreTypesBundle;
@property (nonatomic, retain) NSMutableDictionary* icons;
@property (nonatomic, retain) NSMutableDictionary* systemIcons;
@property (retain) NSImage* miniFile;
@property (retain) NSImage* miniFolder;
@property (retain) NSImage* miniApplication;
@property (retain) NSImage* countBadgeImage;
@property (retain) NSImage* countBadgeImage3;
@property (retain) NSImage* countBadgeImage4;
@property (retain) NSImage* countBadgeImage5;

- (NTIcon *)iconForSystemType:(OSType)iconType;
- (NSImage *)imageWithName:(NSString*)name; // images in CoreTypes.bundle.  for example: ToolbarPicturesFolderIcon

    // special images that are laid over icons
- (NTIcon*)aliasBadge;
- (NTIcon*)lockBadge;
- (NTIcon*)newFolderBadge;
- (NTIcon*)appleScriptBadge;

- (NTIcon*)computerIcon;
- (NTIcon*)documentIcon;
- (NTIcon*)textDocumentIcon;
- (NTIcon*)clippingsDocumentIcon;
- (NTIcon*)folderIcon;
- (NTIcon*)openFolderIcon;
- (NTIcon*)unknownFSObjectIcon;

- (NTIcon*)trashIcon;
- (NTIcon*)trashFullIcon;
- (NTIcon*)ejectIcon;
- (NTIcon*)backwardsIcon;
- (NTIcon*)forwardsIcon;
- (NTIcon*)connectToIcon;
- (NTIcon*)iDiskIcon;
- (NTIcon*)iDiskPublicIcon;
- (NTIcon*)hardDiskIcon;
- (NTIcon*)previewIcon;
- (NTIcon*)iTunesIcon;
- (NTIcon*)colorPanelIcon;

- (NTIcon*)networkIcon;
- (NTIcon*)fileServerIcon;
- (NTIcon*)macFileServerIcon;
- (NTIcon*)genericPCServerIcon;
- (NTIcon*)CDROMIcon;
- (NTIcon*)multipleFilesIcon;
- (NTIcon*)smallMultipleFilesIcon;
- (NTIcon*)spotlightIcon;

- (NTIcon*)homeIcon;
- (NTIcon*)favoritesIcon;
- (NTIcon*)deleteIcon;
- (NTIcon*)finderIcon;
- (NTIcon*)desktopIcon;
- (NTIcon*)windowIcon;
- (NTIcon*)publicIcon;
- (NTIcon*)picturesIcon;
- (NTIcon*)newFolderIcon;
- (NTIcon*)newFileIcon;
- (NTIcon*)musicIcon;
- (NTIcon*)moviesIcon;
- (NTIcon*)infoIcon;
- (NTIcon*)findIcon;
- (NTIcon*)documentsIcon;
- (NTIcon*)applicationsIcon;
- (NTIcon*)noWriteIcon;
- (NTIcon*)writeIcon;
- (NTIcon*)drawerIcon;
- (NTIcon*)burnIcon;
- (NTIcon*)eraseIcon;
- (NTIcon*)recentItemsIcon;
- (NTIcon *)libraryIcon;
- (NTIcon *)sitesIcon;
- (NTIcon *)downloadsIcon;
- (NTIcon *)utilitiesIcon;
- (NTIcon*)stopIcon;
- (NTIcon*)zoomOutIcon;
- (NTIcon*)zoomInIcon;
- (NTIcon*)zoomToActualSizeIcon;
- (NTIcon*)nextPageIcon;
- (NTIcon*)previousPageIcon;
- (NTIcon*)preferencesIcon;
- (NTIcon *)applicationIcon;

- (NTIcon *)screenSharingIcon;
- (NTIcon *)screenSharingNetworkIcon;

- (NTIcon*)rotateLeftIcon;
- (NTIcon*)rotateRightIcon;
@end

@interface NTIconStore (Utilities)
- (NSImage*)miniFolder; // 12x12 generic folder icon (used for brower or tableview)
- (NSImage*)miniFile;  // 12x12 generic file icon
- (NSImage*)miniApplication;  // 12x12 generic file icon

// standard images
- (NSImage*)quickLookImage;
- (NSImage*)slideshowImage;
- (NSImage*)coverflowImage;
- (NSImage*)reloadImage;
- (NSImage*)countBadgeImage:(int)numDigits;
@end





