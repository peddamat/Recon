//
//  NTFSRefObject.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Thu Aug 22 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTIcon, NSDate;

@interface NTFSRefObject : NSObject
{
    FSRef _ref;
	NSDate* referenceDate; // used for the first call to hasBeenModified
    FSCatalogInfo _catalogInfo;
    FSCatalogInfoBitmap _catalogInfoBitmap;
	NSString* nameWhenCreated;  // used to detect if this file has been renamed
	
	BOOL mv_hasBeenModified; // once it's set to YES, that's it
	BOOL mHasBeenRenamed; // once it's set to YES, that's it
	BOOL _isValid;	
}

@property (retain, nonatomic) NSDate* referenceDate;
@property (retain, nonatomic) NSString* nameWhenCreated;

+ (id)refObject:(const FSRef*)ref
	catalogInfo:(FSCatalogInfo*)catalogInfo
		 bitmap:(FSCatalogInfoBitmap)bitmap 
		   name:(NSString*)name;

+ (id)refObjectWithPath:(NSString*)path
			resolvePath:(BOOL)resolvePath;

- (id)initWithRef:(const FSRef*)ref 
	  catalogInfo:(FSCatalogInfo*)catalogInfo 
		   bitmap:(FSCatalogInfoBitmap)bitmap 
			 name:(NSString*)name;

- (FSRef*)ref;
- (BOOL)isValid;
- (BOOL)stillExists;
- (BOOL)hasBeenModified;
- (BOOL)hasBeenRenamed;
- (NSString *)nameWhenCreated;

- (NSString*)path;  // not cached
- (NSString*)name;  // not cached

- (BOOL)isNameLocked;
- (BOOL)isLocked;

	// is the directory or file open
- (BOOL)isOpen;     // not cached

- (NSDate*)creationDate;
- (NSDate*)modificationDate;
- (NSDate*)attributeModificationDate;
- (NSDate*)accessDate;
- (const FileInfo*)fileInfo;
- (FSVolumeRefNum)volumeRefNum;
- (NTIcon*)icon;
- (BOOL)isDirectory;
- (BOOL)isVolume;
- (BOOL)isFile;
- (BOOL)isSymbolicLink;
- (OSType)fileType;
- (OSType)fileCreator;
- (BOOL)isStationery;
- (BOOL)isBundleBitSet;
- (BOOL)isAliasBitSet;
- (int)fileLabel;
- (NSPoint)finderPosition;
- (UInt32)ownerID;
- (NSString *)ownerName;
- (UInt32)groupID;
- (NSString *)groupName;
- (UInt16)modeBits;
- (BOOL)isInvisible;
- (BOOL)isCarbonAlias;
- (BOOL)hasCustomIcon;
- (UInt8)sharingFlags;
- (UInt32)nodeID;
- (unsigned)parentDirID;
- (BOOL)parentIsVolume;
- (NTFSRefObject*)parentFSRef; // not cached
- (BOOL)isParentOfFSRef:(const FSRef*)fsRef;  // used to determine if FSRef is contained by this directory (even if in a subfolder)
- (NSURL*)URL;
- (UInt32)valence;  // folders only

// files only
- (UInt64)dataLogicalSize;
- (UInt64)dataPhysicalSize;
- (UInt64)rsrcLogicalSize;
- (UInt64)rsrcPhysicalSize;

    // call this before you call catalogInfo if you want to make sure this info has been set
- (void)updateCatalogInfo:(FSCatalogInfoBitmap)bitmap;
- (FSCatalogInfo*)catalogInfo;
- (FSCatalogInfoBitmap)catalogInfoBitmap;
@end

@interface NTFSRefObject (Utilities)

+ (BOOL)createFSRef:(FSRef*)outRef fromPath:(const UInt8 *)utf8Path followSymlink:(BOOL)followSymlink;
+ (FSRef*)bootFSRef;

// for optimizing/debugging
+ (void)logFlags:(FSCatalogInfoBitmap)flags;

- (BOOL)isParentOfRefPath:(NSArray*)fsRefPath;  // used to determine if FSRef is contained by this directory

@end

// -----------------------------------------------------------------------------
// constants

extern const int kDefaultCatalogInfoBitmap;
extern const int kDefaultCatalogInfoBitmapForDirectoryScan;
extern const int kSizeCalculatorCatalogInfoBitmap;

