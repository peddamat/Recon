//
//  NTIconStore.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Thu Aug 15 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTIconStore.h"
#import "NTIcon.h"
#import "NTIconFamily.h"
#import "NTPathUtilities.h"
#import "NSImage-CocoatechFile.h"

#define kPFCreatorCode 'PFdR'

#define kPFComputerIconType 'PFcm'
#define kPFTrashEmptyIconType 'PFte'
#define kPFTrashFullIconType 'PFtf'
#define kPFApplicationsIconType 'PFap'
#define kPFDocumentsIconType 'PFdo'
#define kPFFindIconType 'PFfd'
#define kPFInfoIconType 'PFin'
#define kPFMoviesIconType 'PFmv'
#define kPFMusicIconType 'PFmu'
#define kPFNewFolderIconType 'PFnf'
#define kPFNewFileIconType 'PFnF'
#define kPFPicturesIconType 'PFpt'
#define kPFPublicIconType 'PFpu'
#define kPFWindowIconType 'PFwi'
#define kPFEraseIconType 'PFer'
#define kPFDrawerIconType 'PFdW'
#define kPFTextDocumentIconType 'PFtD'
#define kPFMultipleFilesIconType 'PFmF'
#define kPFSmallMultipleFilesIconType 'PFsM'
#define kPFSpotlightIconType 'PFsL'
#define kPFColorPanelIconType 'PFcI'
#define kPFWriteIconType 'PFwR'
#define kPFStopIconType 'PFsI'
#define kPFZoomOutIconType 'PFzO'
#define kPFZoomInIconType 'PFzI'
#define kPFPreferencesIconType 'PFpR'
#define kPFZoomToActualSizeIconType 'PFzA'
#define kPFNextPageIconType 'PFnP'
#define kPFPreviousPageIconType 'PFpP'
#define kPFRotateRightIconType 'PFrR'
#define kPFRotateLeftIconType 'PFrL'
#define kPFToolbarLibraryFolderIcon 'PFlB'
#define kPFToolbarDesktopFolderIcon 'PFdT'
#define kPFToolbarSitesFolderIcon 'PFsT'
#define kPFToolbarDownloadsFolderIcon 'PFdL'
#define kPFNewFolderBadgeIconType 'PFfB'
#define kPFToolbarUtilitiesFolderIcon 'PFuT'
#define kPFPreviewApplicationIcon 'PfPv'
#define kPFITunesApplicationIcon 'PfIt'
#define kPFGenericPCServerIconType 'PfGs'
#define kPFMacServerIcon 'PfMs'
#define kPFScreenSharingIconType 'PfSs'
#define kPFScreenSharingNetworkIconType 'PfSn'

@interface NTIconStore (Private)
- (NTIcon *)iconForType:(OSType)iconType creator:(OSType)creator;

- (void)registerIcon:(int)type;
- (void)registerIconFile:(NTFileDesc*)desc withType:(OSType)type;
- (BOOL)registerImageFile:(NTFileDesc*)desc withType:(OSType)type;  // other image files
- (NTFileDesc*)iconFromSystemIconsBundleWithName:(NSString*)iconName;
- (BOOL)registerImage:(NSImage*)image withType:(OSType)type;
@end

@implementation NTIconStore

@synthesize coreTypesBundle;
@synthesize icons;
@synthesize systemIcons;
@synthesize miniFile;
@synthesize miniFolder;
@synthesize miniApplication, countBadgeImage, countBadgeImage3, countBadgeImage4, countBadgeImage5;

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];
	
    self.icons = [NSMutableDictionary dictionaryWithCapacity:50];
    self.systemIcons = [NSMutableDictionary dictionaryWithCapacity:50];	
	self.coreTypesBundle = [NSBundle bundleWithPath:@"/System/Library/CoreServices/CoreTypes.bundle"];
	
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.coreTypesBundle = nil;
    self.icons = nil;
    self.systemIcons = nil;
    self.miniFile = nil;
    self.miniFolder = nil;
    self.miniApplication = nil;
	self.countBadgeImage = nil;
	
    [super dealloc];
}

- (NTIcon *)iconForSystemType:(OSType)iconType;
{
    return [self iconForType:iconType creator:kSystemIconsCreator];
}

- (NSImage *)imageWithName:(NSString*)name; // images in CoreTypes.bundle.  for example: ToolbarPicturesFolderIcon
{
	NTFileDesc* desc = [self iconFromSystemIconsBundleWithName:name];
	
	return [[[NSImage alloc] initWithContentsOfURL:[desc URL]] autorelease];
}

- (NTIcon*)aliasBadge;
{
    return [self iconForSystemType:kAliasBadgeIcon];
}

- (NTIcon*)lockBadge;
{
    return [self iconForSystemType:kLockedBadgeIcon];
}

- (NTIcon*)appleScriptBadge;
{
    return [self iconForSystemType:kAppleScriptBadgeIcon];
}

- (NTIcon*)newFolderBadge;
{
    return [self iconForType:kPFNewFolderBadgeIconType creator:kPFCreatorCode];
}

- (NTIcon*)documentIcon;
{    
    return [self iconForSystemType:kGenericDocumentIcon];
}

- (NTIcon*)applicationIcon;
{
    return [self iconForSystemType:kGenericApplicationIcon];
}

- (NTIcon*)unknownFSObjectIcon;
{
    return [self iconForSystemType:kUnknownFSObjectIcon];
}

- (NTIcon*)noWriteIcon;
{
    return [self iconForSystemType:kNoWriteIcon];
}

- (NTIcon*)writeIcon;
{
    return [self iconForType:kPFWriteIconType creator:kPFCreatorCode];
}

- (NTIcon*)colorPanelIcon;
{
    return [self iconForType:kPFColorPanelIconType creator:kPFCreatorCode];
}

- (NTIcon*)folderIcon;
{
    return [self iconForSystemType:kGenericFolderIcon];
}

- (NTIcon*)openFolderIcon;
{
    return [self iconForSystemType:kOpenFolderIcon];
}

- (NTIcon*)trashIcon;
{
    return [self iconForSystemType:kTrashIcon];
}

- (NTIcon*)trashFullIcon;
{
    return [self iconForSystemType:kFullTrashIcon];
}

- (NTIcon*)ejectIcon;
{
    return [self iconForSystemType:kEjectMediaIcon];
}

- (NTIcon*)backwardsIcon;
{
    return [self iconForSystemType:kBackwardArrowIcon];
}

- (NTIcon*)forwardsIcon;
{
    return [self iconForSystemType:kForwardArrowIcon];
}

- (NTIcon*)connectToIcon;
{
    return [self iconForSystemType:kConnectToIcon];
}

- (NTIcon*)fileServerIcon;
{
    return [self iconForSystemType:kGenericFileServerIcon];
}

- (NTIcon*)macFileServerIcon;
{
    return [self iconForType:kPFMacServerIcon creator:kPFCreatorCode];
}

- (NTIcon*)networkIcon;
{
    return [self iconForSystemType:kGenericNetworkIcon];
}

- (NTIcon*)CDROMIcon;
{
    return [self iconForSystemType:kGenericCDROMIcon];
}

- (NTIcon*)iDiskIcon;
{
    return [self iconForSystemType:kGenericIDiskIcon];
}

- (NTIcon*)iDiskPublicIcon;
{
    return [self iconForSystemType:kUserIDiskIcon];
}

- (NTIcon*)hardDiskIcon;
{
    return [self iconForSystemType:kGenericHardDiskIcon];    
}

- (NTIcon*)homeIcon;
{
    return [self iconForSystemType:kToolbarHomeIcon];
}

- (NTIcon*)favoritesIcon;
{
    return [self iconForSystemType:kToolbarFavoritesIcon];
}

- (NTIcon*)deleteIcon;
{
    return [self iconForSystemType:kToolbarDeleteIcon];
}

- (NTIcon*)finderIcon;
{
    return [self iconForSystemType:kFinderIcon];
}

//---------------------------------------------------------- 
//  desktopIcon 
//---------------------------------------------------------- 
- (NTIcon *)desktopIcon
{	
    return [self iconForType:kPFToolbarDesktopFolderIcon creator:kPFCreatorCode]; 
}

//---------------------------------------------------------- 
//  sitesIcon 
//---------------------------------------------------------- 
- (NTIcon *)sitesIcon
{
    return [self iconForType:kPFToolbarSitesFolderIcon creator:kPFCreatorCode]; 
}

//---------------------------------------------------------- 
//  libraryIcon 
//---------------------------------------------------------- 
- (NTIcon *)libraryIcon
{
    return [self iconForType:kPFToolbarLibraryFolderIcon creator:kPFCreatorCode]; 
}

//---------------------------------------------------------- 
//  downloadsIcon 
//---------------------------------------------------------- 
- (NTIcon *)downloadsIcon
{
    return [self iconForType:kPFToolbarDownloadsFolderIcon creator:kPFCreatorCode]; 
}

//---------------------------------------------------------- 
//  utilitiesIcon 
//---------------------------------------------------------- 
- (NTIcon *)utilitiesIcon
{
    return [self iconForType:kPFToolbarUtilitiesFolderIcon creator:kPFCreatorCode]; 
}

- (NTIcon*)burnIcon;
{
    return [self iconForSystemType:kBurningIcon];
}

- (NTIcon*)eraseIcon;
{
    return [self iconForType:kPFEraseIconType creator:kPFCreatorCode];
}

- (NTIcon*)multipleFilesIcon;
{
    return [self iconForType:kPFMultipleFilesIconType creator:kPFCreatorCode];
}

- (NTIcon*)smallMultipleFilesIcon;
{
    return [self iconForType:kPFSmallMultipleFilesIconType creator:kPFCreatorCode];
}

- (NTIcon*)spotlightIcon;
{
    return [self iconForType:kPFSpotlightIconType creator:kPFCreatorCode];
}

- (NTIcon *)screenSharingIcon;
{
	return [self iconForType:kPFScreenSharingIconType creator:kPFCreatorCode];
}

- (NTIcon *)screenSharingNetworkIcon;
{
	return [self iconForType:kPFScreenSharingNetworkIconType creator:kPFCreatorCode];
}

- (NTIcon*)recentItemsIcon;
{
    return [self iconForSystemType:kRecentItemsIcon];
}

- (NTIcon*)windowIcon;
{
	// system icon looks like shit
	// return [self iconForSystemType:kGenericWindowIcon];
    return [self iconForType:kPFWindowIconType creator:kPFCreatorCode];
}

- (NTIcon*)genericPCServerIcon;
{
	return [self iconForType:kPFGenericPCServerIconType creator:kPFCreatorCode];
}

- (NTIcon*)publicIcon;
{
    return [self iconForType:kPFPublicIconType creator:kPFCreatorCode];
}

- (NTIcon*)computerIcon;
{
    return [self iconForType:kPFComputerIconType creator:kPFCreatorCode];
}

- (NTIcon*)picturesIcon;
{
    return [self iconForType:kPFPicturesIconType creator:kPFCreatorCode];
}

- (NTIcon*)newFolderIcon;
{
    return [self iconForType:kPFNewFolderIconType creator:kPFCreatorCode];
}

- (NTIcon*)newFileIcon;
{
    return [self iconForType:kPFNewFileIconType creator:kPFCreatorCode];
}

- (NTIcon*)musicIcon;
{
    return [self iconForType:kPFMusicIconType creator:kPFCreatorCode];
}

- (NTIcon*)moviesIcon;
{
    return [self iconForType:kPFMoviesIconType creator:kPFCreatorCode];
}

- (NTIcon*)infoIcon;
{
    return [self iconForType:kPFInfoIconType creator:kPFCreatorCode];
}

- (NTIcon*)findIcon;
{
    return [self iconForType:kPFFindIconType creator:kPFCreatorCode];
}

- (NTIcon*)previewIcon;
{
    return [self iconForType:kPFPreviewApplicationIcon creator:kPFCreatorCode];
}

- (NTIcon*)iTunesIcon;
{
    return [self iconForType:kPFITunesApplicationIcon creator:kPFCreatorCode];
}

- (NTIcon*)documentsIcon;
{
    return [self iconForType:kPFDocumentsIconType creator:kPFCreatorCode];
}

- (NTIcon*)applicationsIcon;
{
    return [self iconForType:kPFApplicationsIconType creator:kPFCreatorCode];
}

- (NTIcon*)drawerIcon;
{
    return [self iconForType:kPFDrawerIconType creator:kPFCreatorCode];
}

- (NTIcon*)textDocumentIcon;
{
    return [self iconForType:kPFTextDocumentIconType creator:kPFCreatorCode];
}

- (NTIcon*)clippingsDocumentIcon;
{
    return [self iconForSystemType:kClippingTextTypeIcon];
}

- (NTIcon*)stopIcon;
{
    return [self iconForType:kPFStopIconType creator:kPFCreatorCode];
}

- (NTIcon*)zoomOutIcon;
{
    return [self iconForType:kPFZoomOutIconType creator:kPFCreatorCode];
}

- (NTIcon*)preferencesIcon;
{    
    return [self iconForType:kPFPreferencesIconType creator:kPFCreatorCode];
}

- (NTIcon*)zoomInIcon;
{
    return [self iconForType:kPFZoomInIconType creator:kPFCreatorCode];
}

- (NTIcon*)zoomToActualSizeIcon;
{
    return [self iconForType:kPFZoomToActualSizeIconType creator:kPFCreatorCode];
}

- (NTIcon*)nextPageIcon;
{
    return [self iconForType:kPFNextPageIconType creator:kPFCreatorCode];
}

- (NTIcon*)previousPageIcon;
{
    return [self iconForType:kPFPreviousPageIconType creator:kPFCreatorCode];
}

//---------------------------------------------------------- 
//  rotateLeftIcon 
//---------------------------------------------------------- 
- (NTIcon *)rotateLeftIcon
{
    return [self iconForType:kPFRotateLeftIconType creator:kPFCreatorCode]; 
}

//---------------------------------------------------------- 
//  rotateRightIcon 
//---------------------------------------------------------- 
- (NTIcon *)rotateRightIcon
{
    return [self iconForType:kPFRotateRightIconType creator:kPFCreatorCode]; 
}

@end

@implementation NTIconStore (Utilities)

- (NSImage *)miniFile
{
	@synchronized(self) {
		if (!miniFile)
			self.miniFile = [[[NTIconStore sharedInstance] documentIcon] imageForSize:12 label:0 select:NO];
	}
    return miniFile; 
}

- (NSImage *)miniFolder
{
	@synchronized(self) {
		if (!miniFolder)
			self.miniFolder = [[[NTIconStore sharedInstance] folderIcon] imageForSize:12 label:0 select:NO];
	}
	
    return miniFolder; 
}

- (NSImage *)miniApplication
{
	@synchronized(self) {
		if (!miniApplication)
			self.miniApplication = [[[NTIconStore sharedInstance] applicationIcon] imageForSize:12 label:0 select:NO];
	}
	
    return miniApplication; 
}

- (NSImage*)quickLookImage;
{
    return [NSImage imageNamed:NSImageNameQuickLookTemplate];
}

- (NSImage*)slideshowImage;
{
    return [NSImage imageNamed:NSImageNameSlideshowTemplate];
}

- (NSImage*)coverflowImage;
{
    return [NSImage imageNamed:NSImageNameFlowViewTemplate];
}

- (NSImage*)reloadImage;
{
    return [NSImage imageNamed:NSImageNameRefreshTemplate];
}

- (NSImage*)countBadgeImage:(int)numDigits;
{
	NSString* imageName = nil;
	NSString* path = nil;
	
	if (numDigits < 3)
	{
		@synchronized(self) {
			if (!self.countBadgeImage)
			{
				imageName = @"countBadge.png";
				path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
				if (path)
					self.countBadgeImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
			}			
		}
		
		return self.countBadgeImage;
	}
	if (numDigits == 3)
	{
		@synchronized(self) {
			if (!self.countBadgeImage3)
			{
				imageName = @"countBadge3.png";
				path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
				if (path)
					self.countBadgeImage3 = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
			}		
		}
		return self.countBadgeImage3;
	}
	if (numDigits == 4)
	{
		@synchronized(self) {
			if (!self.countBadgeImage4)
			{
				imageName = @"countBadge4.png";
				path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
				if (path)
					self.countBadgeImage4 = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
			}
		}
		
		return self.countBadgeImage4;
	}
	
	@synchronized(self) {
		if (!self.countBadgeImage5)
		{
			imageName = @"countBadge5.png";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			if (path)
				self.countBadgeImage5 = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
		}
	}
	
    return self.countBadgeImage5; 
}

@end

@implementation NTIconStore (Private)

- (NTIcon *)iconForType:(OSType)iconType creator:(OSType)creator;
{
    NTIcon* result=nil;
    OSStatus err;
    IconRef iconRef;
	NSNumber* theKey = [NSNumber numberWithUnsignedInt:iconType];
	
	// thread protect the mutable arrays
	@synchronized(self) {
		if (creator == kPFCreatorCode)
		{
			result = [self.icons objectForKey:theKey];
			if (!result)
			{
				if (iconType == kPFPreviewApplicationIcon)
				{
					NSString* path = [NTPathUtilities fullPathForApplication:@"Preview.app"];
					if (path)
					{
						NTFileDesc *desc = [NTFileDesc descResolve:path];
						
						if ([desc isValid])
							result = [[desc icon] retain];
					}
				}
				else if (iconType == kPFITunesApplicationIcon)
				{
					NSString* path = [NTPathUtilities fullPathForApplication:@"iTunes.app"];
					if (path)
					{
						NTFileDesc *desc = [NTFileDesc descResolve:path];
						
						if ([desc isValid])
							result = [[desc icon] retain];
					}				
				}
				else
				{
					// lazily registering icons
					[self registerIcon:iconType];
					
					err = GetIconRef(kOnSystemDisk, creator, iconType, &iconRef);
					if (!err)
					{
						result = [NTIcon iconWithRef:iconRef];
						ReleaseIconRef(iconRef);
					}
				}
				
				// add to cache
				if (result)
					[self.icons setObject:result forKey:theKey];
			}
		}
		else
		{
			result = [self.systemIcons objectForKey:theKey];
			if (!result)
			{
				err = GetIconRef(kOnSystemDisk, creator, iconType, &iconRef);
				if (!err)
				{
					result = [NTIcon iconWithRef:iconRef];
					ReleaseIconRef(iconRef);
				}
				
				// add to cache
				if (result)
					[self.systemIcons setObject:result forKey:theKey];			
			}			
		}
	}
	
    return result;
}

// the computer icon is not one of the default system icons
// we need this in IconRef format, so add it here.
- (void)registerIcon:(int)type;
{
    NSString* imageName;
    NSString* path;
    NTFileDesc* desc;
	
	switch (type) 
	{
		case kPFApplicationsIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarAppsFolderIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFApplicationsIconType];
		}
			break;
		case kPFDocumentsIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarDocumentsFolderIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFDocumentsIconType];			
		}
			break;
		case kPFFindIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"MagnifyingGlassIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFFindIconType];			
		}
			break;
		case kPFInfoIconType:
		{
			[self registerImage:[NSImage imageNamed:NSImageNameInfo] withType:kPFInfoIconType];  
		}
			break;
		case kPFMoviesIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarMovieFolderIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFMoviesIconType];			
		}
			break;
		case kPFMusicIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarMusicFolderIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFMusicIconType];			
		}
			break;
		case kPFNewFolderBadgeIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"NewFolderBadgeIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFNewFolderBadgeIconType];			
		}
			break;
		case kPFNewFolderIconType:
		{
			NSImage *newFolder = [[self folderIcon] imageForSize:128 label:0 select:NO];
			newFolder = [newFolder imageWithBadge:[self newFolderBadge]];
			[self registerImage:newFolder withType:kPFNewFolderIconType];
		}
			break;
		case kPFNewFileIconType:
		{
			NSImage *newFile = [[self documentIcon] imageForSize:128 label:0 select:NO];
			newFile = [newFile imageWithBadge:[self newFolderBadge]];
			[self registerImage:newFile withType:kPFNewFileIconType];			
		}
			break;
		case kPFDrawerIconType:
		{
			imageName = @"drawer_local.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFDrawerIconType];			
		}
			break;
		case kPFTextDocumentIconType:
		{
			imageName = @"textDocument.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFTextDocumentIconType];			
		}
			break;
		case kPFPicturesIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarPicturesFolderIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFPicturesIconType];			
		}
			break;
		case kPFPublicIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarPublicFolderIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFPublicIconType];			
		}
			break;
		case kPFGenericPCServerIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"public.generic-pc"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFGenericPCServerIconType];			
		}
			break;
		case kPFComputerIconType:
		{
			[self registerImage:[NSImage imageNamed:NSImageNameComputer] withType:kPFComputerIconType];  
		}
			break;
		case kPFWindowIconType:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"GenericWindowIcon"];
			if ([desc isValid])
				[self registerIconFile:desc withType:kPFWindowIconType];			
		}
			break;
		case kPFToolbarLibraryFolderIcon:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarLibraryFolderIcon"];
			if ([desc isValid])  
				[self registerIconFile:desc withType:kPFToolbarLibraryFolderIcon];			
		}
			break;
		case kPFToolbarDownloadsFolderIcon:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarDownloadsFolderIcon"];
			if ([desc isValid])  
				[self registerIconFile:desc withType:kPFToolbarDownloadsFolderIcon];			
		}
			break;
		case kPFToolbarUtilitiesFolderIcon:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarUtilitiesFolderIcon"];
			if ([desc isValid])  
				[self registerIconFile:desc withType:kPFToolbarUtilitiesFolderIcon];			
		}
			break;
		case kPFToolbarDesktopFolderIcon:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarDesktopFolderIcon"];
			if ([desc isValid])  
				[self registerIconFile:desc withType:kPFToolbarDesktopFolderIcon];			
		}
			break;
		case kPFToolbarSitesFolderIcon:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"ToolbarSitesFolderIcon"];
			if ([desc isValid])  
				[self registerIconFile:desc withType:kPFToolbarSitesFolderIcon];			
		}
			break;
		case kPFMacServerIcon:
		{
			desc = [self iconFromSystemIconsBundleWithName:@"com.apple.mac"];
			if ([desc isValid])  
				[self registerIconFile:desc withType:kPFMacServerIcon];			
		}
			break;
		case kPFEraseIconType:
		{
			[self registerImage:[NSImage imageNamed:DREraseIcon] withType:kPFEraseIconType];  
		}
			break;
		case kPFColorPanelIconType:
		{
			[self registerImage:[NSImage imageNamed:NSImageNameColorPanel] withType:kPFColorPanelIconType];  
		}
			break;
		case kPFWriteIconType:
		{
			imageName = @"writeIcon.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFWriteIconType];			
		}
			break;
		case kPFScreenSharingIconType:
		{
			imageName = @"screenSharing.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFScreenSharingIconType];			
		}
			break;
		case kPFScreenSharingNetworkIconType:
		{
			imageName = @"screenSharingNetwork.tif";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerImageFile:desc withType:kPFScreenSharingNetworkIconType];			
		}
			break;
		case kPFSmallMultipleFilesIconType:
			[self registerImage:[NSImage imageNamed:NSImageNameMultipleDocuments] withType:kPFSmallMultipleFilesIconType];  
			break;
		case kPFMultipleFilesIconType:
		{
			// [NSImage imageNamed:NSImageNameMultipleDocuments]
			NSImage *image = [[self documentIcon] imageForSize:384 label:0 select:NO];
			
			NTImageMaker *imageMaker = [NTImageMaker maker:NSMakeSize(512, 512)];
			[imageMaker lockFocus];
			{
				int offsetX = 40;
				int offsetY = 18;
				int start = (512-384) / 2;
				
				[image compositeToPointHQ:NSMakePoint(start+offsetX, start+offsetY) operation:NSCompositeSourceOver fraction:1];
				[image compositeToPointHQ:NSMakePoint(start, start) operation:NSCompositeSourceOver fraction:1];
				[image compositeToPointHQ:NSMakePoint(start-offsetX, start-offsetY) operation:NSCompositeSourceOver fraction:1];
			}
			image = [imageMaker unlockFocus];
			
			[self registerImage:image withType:kPFMultipleFilesIconType];  
		}
			break;
		case kPFSpotlightIconType:
		{
			imageName = @"spotlight.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFSpotlightIconType];  			
		}
			break;
		case kPFStopIconType:
		{
			imageName = @"stop_local.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFStopIconType];  			
		}
			break;
		case kPFNextPageIconType:
		{
			imageName = @"nextPage_local.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFNextPageIconType];  			
		}
			break;
		case kPFPreviousPageIconType:
		{
			imageName = @"previousPage_local.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFPreviousPageIconType];  			
		}
			break;
		case kPFZoomInIconType:
		{
			imageName = @"zoomIn_local.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFZoomInIconType];  			
		}
			break;
		case kPFZoomOutIconType:
		{
			imageName = @"zoomOut_local.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFZoomOutIconType];  			
		}
			break;
		case kPFZoomToActualSizeIconType:
		{
			imageName = @"zoomToActualSize_local.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFZoomToActualSizeIconType];  			
		}
			break;
		case kPFRotateLeftIconType:
		{
			imageName = @"RotateLeftToolbarImage.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFRotateLeftIconType];  
		}
			break;
		case kPFRotateRightIconType:
		{
			imageName = @"RotateRightToolbarImage.icns";
			path = [[self bundle] pathForResource:[imageName stringByDeletingPathExtension] ofType:[imageName pathExtension] inDirectory:@"images"];
			desc = [NTFileDesc descNoResolve:path];
			[self registerIconFile:desc withType:kPFRotateRightIconType];  			
		}
			break;
		case kPFPreferencesIconType:
		{
			[self registerImage:[NSImage imageNamed:NSImageNamePreferencesGeneral] withType:kPFPreferencesIconType];  
		}
			break;
		default:
			NSLog(@"icon type not found?");
			break;
	}
}

// works with icns files only
- (void)registerIconFile:(NTFileDesc*)desc withType:(OSType)type;
{
    OSStatus err;
    IconRef iconRef;
	
    if ([desc isValid])
	{
        err = RegisterIconRefFromFSRef(kPFCreatorCode, type, [desc FSRefPtr], &iconRef);
		
		// os bug
		// if (!err)
		// ReleaseIconRef(iconRef);
	}
}

// used for non .icns files (RegisterIconRefFromFSRef only works for icns files)
- (BOOL)registerImageFile:(NTFileDesc*)desc withType:(OSType)type;
{
    NSImage* image = [[[NSImage alloc] initWithContentsOfURL:[desc URL]] autorelease];
    
    if (image)
		return [self registerImage:image withType:type];
    
    return NO;
}

- (BOOL)registerImage:(NSImage*)image withType:(OSType)type;
{
    NTIconFamily* iconFamily;
    OSStatus err = 1;  // default is error
    
    if (image)
    {
        iconFamily = [NTIconFamily iconFamilyWithImage:image];
        if (iconFamily)
        {
            IconRef iconRef;
            IconFamilyHandle handle = [iconFamily iconFamilyHandle];
            
            if (handle)
			{
				err = RegisterIconRefFromIconFamily(kPFCreatorCode, type, handle, &iconRef);
				
				// os bug?
				// if (!err)
				//	ReleaseIconRef(iconRef);
			}
        }
    }
    
    return (err == noErr);
}

- (NTFileDesc*)iconFromSystemIconsBundleWithName:(NSString*)iconName;
{
	NSString* path = [self.coreTypesBundle pathForImageResource:iconName];
	NTFileDesc* desc;
	
	if (path)
	{
		desc = [NTFileDesc descNoResolve:path];
		
		if (desc && [desc isValid])
			return desc;
	}
	
    return nil;
}

@end
