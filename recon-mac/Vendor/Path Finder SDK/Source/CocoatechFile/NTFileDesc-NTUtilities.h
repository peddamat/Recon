//
//  NTFileDesc-NTUtilities.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/13/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc.h"

@interface NTFileDesc (NTUtilities)

// convienience constructors
+ (NTFileDesc*)descNoResolve:(NSString*)path;
+ (NTFileDesc*)descResolve:(NSString*)path;
    // the descResolve won't resolve server aliases, this is for speed, but you can always call this to get a completely resolved server desc
+ (NTFileDesc*)descResolveServerAlias:(NSString*)path;

+ (NTFileDesc*)descFSRef:(const FSRef*)ref;

+ (NTFileDesc*)descFSRefObject:(NTFSRefObject*)refObject;
+ (NTFileDesc*)descVolumeRefNum:(FSVolumeRefNum)vRefNum;

+ (NTFileDesc*)bootVolumeDesc;
+ (FSRef*)bootFSRef;

+ (NTFileDesc*)mainBundleDesc;

+ (BOOL)isNetworkURLDesc:(NTFileDesc*)desc;

+ (NTFileDesc*)inValid;

+ (UInt64)volumeTotalBytes:(NTFileDesc*)inDesc;
+ (UInt64)volumeFreeBytes:(NTFileDesc*)inDesc;

	// convert an array of paths to an array of NTFileDescs
+ (NSMutableArray*)descsStillExist:(NSArray*)descs;
+ (NSMutableArray*)descsToPaths:(NSArray*)descs;
+ (NSMutableArray*)descsToNames:(NSArray*)descs;
+ (NSMutableArray*)pathsToDescs:(NSArray*)paths;
+ (NSMutableArray*)descsToURLs:(NSArray*)descs;
+ (NSMutableArray*)urlsToDescs:(NSArray*)urls;
+ (NSMutableArray*)urlsToPaths:(NSArray*)urls;
+ (NSMutableArray*)pathsToURLs:(NSArray*)paths;

+ (NSMutableArray*)descsToFilesAndFolders:(NSArray*)theDescs
							   outFolders:(NSMutableArray**)outFolders
				   treatPackagesAsFolders:(BOOL)treatPackagesAsFolders;

+ (NSMutableArray*)standardizePaths:(NSArray*)paths;
+ (NSMutableArray*)badURLs:(NSArray*)urls;  // urls that fail to create a NTFileDesc
+ (NSArray*)expandedPaths:(NSArray*)inPaths;
+ (NSMutableArray*)descsNoDuplicates:(NSArray*)descs;

+ (NSMutableArray*)newDescs:(NSArray*)descs;

+ (NSArray*)arrayByResolvingAliases:(NSArray*)inDescs;
+ (NSArray*)arrayByRecreatingDescs:(NSArray*)inDescs;

+ (NSMutableArray*)descsToAliases:(NSArray*)descs;
+ (NSMutableArray*)aliasesToDescs:(NSArray*)aliases;

+ (NSString*)kindStringForExtension:(NSString*)extension;
+ (NTFileDesc*)applicationForExtension:(NSString*)extension;
+ (NTFileDesc*)applicationForType:(OSType)type creator:(OSType)creator extension:(NSString*)extension;

+ (NSArray*)removeDescsWithParentInList:(NSArray*)srcDescs;
+ (NSArray*)parentFoldersForDescs:(NSArray*)descs;

// changes files to their parent directory
+ (NSArray*)foldersForDescs:(NSArray*)descs;

- (NSMenu*)pathMenu:(SEL)action target:(id)target;
- (NSMenu*)pathMenu:(SEL)action target:(id)target fontSize:(int)fontSize;

// cached forknames
+ (NSString*)dataForkName;
+ (NSString*)rsrcForkName;

// if moving, deleting, copying, burning or whatever, remove ._file is it's parent is already included to avoid a duplication of effort.  let the OS deal with the ._ files
// the user may be showing invisible files and think they need to select the matching ._ file
// you should check: if (![[self volume] supportsForks]) before calling to save time
+ (NSArray*)stripOutDuplicateDotUnderscoreFiles:(NSArray*)descs;

+ (BOOL)parentDirectoriesWritable:(NSArray*)sources;
+ (BOOL)directoriesWritable:(NSArray*)sources;

	// -[NTFileDesc valence] returns 0 for non-HFS disks, so use this instead
- (UInt32)valenceForNonHFS;

+ (BOOL)descOK:(NTFileDesc*)desc;
+ (BOOL)hasResourceFork:(NTFileDesc*)desc;
+ (void)deleteResourceFork:(NTFileDesc*)desc;
+ (void)deleteDataFork:(NTFileDesc*)desc;
+ (void)setResourceFork:(NTFileDesc*)desc length:(UInt64)length;
+ (void)setDataFork:(NTFileDesc*)desc length:(UInt64)length;
+ (void)copy:(NTFileDesc*)srcDesc fromDataFork:(BOOL)fromDataFork to:(NTFileDesc*)destDesc toDataFork:(BOOL)toDataFork;

+ (NSString*)permissionsTextForDesc:(NTFileDesc*)desc includeOctal:(BOOL)includeOctal;
+ (NSString*)permissionsTextForModeBits:(unsigned long)modeBits includeOctal:(BOOL)includeOctal;
+ (NSString*)permissionOctalStringForModeBits:(unsigned long)modeBits;
@end

