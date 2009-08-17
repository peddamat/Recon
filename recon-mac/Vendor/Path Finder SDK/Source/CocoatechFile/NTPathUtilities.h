//
//  NTPathUtilities.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTPathUtilities : NSObject {

}

+ (BOOL)pathOK:(NSString*)path;

+ (NSString*)fullPathForApplication:(NSString*)appName;

	// class utility methods
+ (NSString*)pathFromRef:(const FSRef*)ref;

	// compares two HFSUniStr255 for equality
	// return true if they are identical, false if not
+ (BOOL)compareHFSUniStr255:(const HFSUniStr255 *)lhs
						rhs:(const HFSUniStr255 *)rhs;

@end

// methods for NSString 

@interface NSString (NTCarbonUtilities)

+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef;
- (BOOL)getFSRef:(FSRef *)aFSRef;

- (NSString *)resolveAliasFile;

@end

// -----------------------------------------------
// c functions extracted from more files X

/*
 *	FSGetFinderInfo and FSSetFinderInfo use these unions for Finder information.
 */

union FinderInfo
{
	FileInfo				file;
	FolderInfo			folder;
};
typedef union FinderInfo FinderInfo;

union ExtendedFinderInfo
{
	ExtendedFileInfo		file;
	ExtendedFolderInfo	folder;
};
typedef union ExtendedFinderInfo ExtendedFinderInfo;

OSStatus FSMakeFSRef(FSVolumeRefNum volRefNum,
					 SInt32 dirID,
					 NSString* fileName,
					 FSRef *outRef);

OSErr FSSetHasCustomIcon(const FSRef *ref);

OSErr FSClearHasCustomIcon(const FSRef *ref);

OSErr FSSetInvisible(const FSRef *ref);

OSErr FSClearInvisible(const FSRef *ref);

OSErr FSChangeFinderFlags(const FSRef *ref,
						  Boolean setBits,
						  UInt16 flagBits);

