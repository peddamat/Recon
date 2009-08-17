//
//  NTFSRefObject.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Thu Aug 22 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import "NTFSRefObject.h"
#import <Carbon/Carbon.h>
#import "NTIcon.h"
#import <sys/stat.h>

const int kDefaultCatalogInfoBitmap = (kFSCatInfoNodeFlags | 
									   kFSCatInfoPermissions | 
									   kFSCatInfoFinderInfo | 
									   kFSCatInfoParentDirID |
									   kFSCatInfoVolume | 
									   kFSCatInfoNodeID
);

// used when calcing size of folders/files
const int kSizeCalculatorCatalogInfoBitmap = (kFSCatInfoNodeFlags | 
											  kFSCatInfoPermissions | 
											  kFSCatInfoFinderInfo | 
											  kFSCatInfoParentDirID |
											  kFSCatInfoVolume | 
											  kFSCatInfoNodeID |
											  kFSCatInfoDataSizes |
											  kFSCatInfoRsrcSizes
);

const int kDefaultCatalogInfoBitmapForDirectoryScan = (kFSCatInfoNodeFlags |
													   kFSCatInfoFinderInfo
);

@interface NTFSRefObject (Private)
- (BOOL)flagsNeedUpdate:(FSCatalogInfoBitmap)flags;
- (void)updateForFlags:(FSCatalogInfoBitmap)flags;
- (void)clearFlags:(FSCatalogInfoBitmap)flags;

- (BOOL)checkHasBeenModified;
@end

@implementation NTFSRefObject

@synthesize referenceDate, nameWhenCreated;

- (id)initWithRef:(const FSRef*)ref
	  catalogInfo:(FSCatalogInfo*)catalogInfo
		   bitmap:(FSCatalogInfoBitmap)bitmap
			 name:(NSString*)name;
{
    self = [super init];
	
    _isValid = NO;
	
    if (catalogInfo)
    {
        _catalogInfo = *catalogInfo;
        _catalogInfoBitmap = bitmap;
    }
	
    if (ref)
    {
        _ref = *ref;  // copy the ref
        _isValid = YES;
    }
    
    // used for the first call to hasBeenModified, avoid autorelease pool hit
	NSDate* date = [[NSDate alloc] init];
	[self setReferenceDate:date];
	[date release];
	
	// used to detect a rename
	if ([name length])
		[self setNameWhenCreated:name];
	else
		[self setNameWhenCreated:[self name]];
	
    return self;
}

- (id)initWithPath:(NSString*)path 
	   resolvePath:(BOOL)resolvePath;
{
    FSRef ref;
    BOOL success = NO;
	
    if (path && [path length])
		success = [[self class] createFSRef:&ref fromPath:(const UInt8 *)[path UTF8String] followSymlink:resolvePath];
	
    if (success)
        self = [self initWithRef:&ref catalogInfo:nil bitmap:0 name:[path lastPathComponent]];
    else
        self = [self initWithRef:nil catalogInfo:nil bitmap:0 name:[path lastPathComponent]];
	
    return self;
}

+ (id)refObject:(const FSRef*)ref catalogInfo:(FSCatalogInfo*)catalogInfo bitmap:(FSCatalogInfoBitmap)bitmap name:(NSString*)name;
{
    NTFSRefObject* result = [[NTFSRefObject alloc] initWithRef:ref catalogInfo:catalogInfo bitmap:bitmap name:name];
	
    return [result autorelease];
}

+ (id)refObjectWithPath:(NSString*)path resolvePath:(BOOL)resolvePath;
{
    NTFSRefObject* result = [[NTFSRefObject alloc] initWithPath:path resolvePath:resolvePath];
	
    // need to check for the case of modeBits == 0 and get the ref using the full path (resolves mountpoints)
    if (!resolvePath && [result isValid])
    {
        if ([result modeBits] == 0)
        {
            [result autorelease];
            result = [[NTFSRefObject alloc] initWithPath:path resolvePath:YES];
        }
    }
	
    return [result autorelease];
}

- (void)dealloc;
{
	self.referenceDate = nil;
	self.nameWhenCreated = nil;
	
    [super dealloc];
}

- (FSRef*)ref;
{
    if (_isValid)
        return &_ref;
	
    return nil;
}

- (NSString*)path;
{
	NSString* result=nil;
	
	// we don't cache the paths, they are expensive to build, but could change if a parent or volume is renamed
    if (_isValid)
    {
		CFURLRef url = CFURLCreateFromFSRef( kCFAllocatorDefault, &_ref );
		if (url)
		{
			CFStringRef cfString = CFURLCopyFileSystemPath( url, kCFURLPOSIXPathStyle );
			CFRelease(url);
			
			if (cfString)
			{
				result = [NSString stringWithString:(NSString*)cfString];
				CFRelease(cfString);
			}
		}
	}
	
    return result;
}

- (NSString*)name;
{
	if (!_isValid)
		return @"";
	
	// this works, but probably slower
	// 	return [[self path] lastPathComponent];
	
	// NOTE: FSGetCatalogInfo returns the hard disk name for "/", so catch that here 
	if (FSCompareFSRefs([NTFSRefObject bootFSRef], &_ref) == noErr) 
		return @"/"; 
	else 
	{ 
		HFSUniStr255 name; 
		OSErr err = FSGetCatalogInfo(&_ref, kFSCatInfoNone, NULL, &name, NULL, NULL); 
		
		if (!err) 
			return [NSString fileNameWithHFSUniStr255:&name]; 
	} 
	
	return @""; 
}

- (BOOL)isValid;
{
    return _isValid;
}

- (BOOL)isNameLocked;
{
    if (!_isValid)
        return NO;
	
    [self updateForFlags:kFSCatInfoFinderInfo];
	
    return ((((FileInfo*)_catalogInfo.finderInfo)->finderFlags & kNameLocked) != 0);
}

- (BOOL)isLocked;
{
    if (!_isValid)
        return NO;
	
    [self updateForFlags:kFSCatInfoNodeFlags];
	
    return ((_catalogInfo.nodeFlags & kFSNodeLockedMask) != 0);
}

- (UInt32)valence;
{
    if (!_isValid || [self isFile])
        return 0;
    
    [self updateForFlags:kFSCatInfoValence];
    
    return _catalogInfo.valence;    
}

- (NSDate*)modificationDate;
{
    if (!_isValid)
        return [NSDate distantPast];
	
    [self updateForFlags:kFSCatInfoContentMod];
	
    return [NSDate dateFromUTCDateTime:_catalogInfo.contentModDate];
}

- (NSDate*)creationDate;
{
    if (!_isValid)
        return [NSDate distantPast];
	
    [self updateForFlags:kFSCatInfoCreateDate];
	
    return [NSDate dateFromUTCDateTime:_catalogInfo.createDate];
}

- (NSDate*)attributeModificationDate;
{
    if (!_isValid)
        return [NSDate distantPast];
	
    [self updateForFlags:kFSCatInfoAttrMod];
	
    return [NSDate dateFromUTCDateTime:_catalogInfo.attributeModDate];
}

- (NSDate*)accessDate;
{
    if (!_isValid)
        return [NSDate distantPast];
	
    [self updateForFlags:kFSCatInfoAccessDate];
	
    return [NSDate dateFromUTCDateTime:_catalogInfo.accessDate];
}

- (const FileInfo*)fileInfo;
{
    if (!_isValid)
        return nil;
	
    [self updateForFlags:kFSCatInfoFinderInfo];
	
    return ((FileInfo*)_catalogInfo.finderInfo);
}

- (FSVolumeRefNum)volumeRefNum;
{
    if (!_isValid)
        return 0;
	
    [self updateForFlags:kFSCatInfoVolume];
	
    return _catalogInfo.volume;
}

- (NTIcon*)icon
{
    NTIcon* icon = nil;
	
    if (_isValid)
    {
        SInt16 outLabel;
        OSStatus err;
        IconRef iconRef;
		
        [self updateForFlags:kIconServicesCatalogInfoMask];
		
        NS_DURING
		err = GetIconRefFromFileInfo(&_ref,
									 0,
									 nil,
									 _catalogInfoBitmap,
									 &_catalogInfo,
									 kIconServicesNormalUsageFlag,
									 &iconRef,
									 &outLabel);
		
        NS_HANDLER
		err = 1;
        NS_ENDHANDLER
		
        if (err == noErr)
        {
            icon = [NTIcon iconWithRef:iconRef];
			
            // release icon ref
            ReleaseIconRef(iconRef);
        }
    }
	
    return icon;
}

- (BOOL)isFile;
{
    return ![self isDirectory];
}

- (BOOL)isDirectory;
{
    if (!_isValid)
        return NO;
	
    [self updateForFlags:kFSCatInfoNodeFlags];
	
    return ((_catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0);
}

- (unsigned)parentDirID;
{
    if (!_isValid)
        return 0;
	
	[self updateForFlags:kFSCatInfoParentDirID];
	return (_catalogInfo.parentDirID);
}

// is the directory or file open
- (BOOL)isOpen;
{
	if (!_isValid)
        return NO;
	
	// get the item fresh each time, don't want cached value
	[self clearFlags:kFSCatInfoNodeFlags];
	[self updateForFlags:kFSCatInfoNodeFlags];
	
    return ((_catalogInfo.nodeFlags & kFSNodeForkOpenMask) != 0);
}

- (BOOL)parentIsVolume;
{
    if (!_isValid)
        return NO;
	
    return ([self parentDirID] == fsRtDirID);
}

- (BOOL)isVolume;
{
    if (!_isValid)
        return NO;
	
    if ([self isDirectory])
        return ([self parentDirID] == fsRtParID);
	
    return NO;
}

- (OSType)fileType;
{
    if (!_isValid)
        return 0;
	
    if ([self isFile])
    {
        [self updateForFlags:kFSCatInfoFinderInfo];
		
        return ((FileInfo*)_catalogInfo.finderInfo)->fileType;
    }
	
    return 0;
}

- (OSType)fileCreator;
{
    if (!_isValid)
        return 0;
	
    if ([self isFile])
    {
        [self updateForFlags:kFSCatInfoFinderInfo];
		
        return ((FileInfo*)_catalogInfo.finderInfo)->fileCreator;
    }
	
    return 0;
}

- (BOOL)isStationery;
{
    if (!_isValid)
        return NO;
	
    [self updateForFlags:kFSCatInfoFinderInfo];
	
    return ((((FileInfo*)_catalogInfo.finderInfo)->finderFlags & kIsStationery) != 0);
}

- (BOOL)isBundleBitSet;
{
    if (!_isValid)
        return NO;
    
    [self updateForFlags:kFSCatInfoFinderInfo];
    
    return ((((FileInfo*)_catalogInfo.finderInfo)->finderFlags & kHasBundle) != 0);
}

- (BOOL)isAliasBitSet;
{
    if (!_isValid)
        return NO;
    
    [self updateForFlags:kFSCatInfoFinderInfo];
    
    return ((((FileInfo*)_catalogInfo.finderInfo)->finderFlags & kIsAlias) != 0);
}

- (int)fileLabel;
{
    if (!_isValid)
        return 0;
	
    [self updateForFlags:kFSCatInfoFinderInfo];
	
    return ((((FileInfo*)_catalogInfo.finderInfo)->finderFlags & kColor) >> 1);
}

- (NSPoint)finderPosition;
{
    Point carbonPoint;
	
    if (!_isValid)
        return NSZeroPoint;
	
    [self updateForFlags:kFSCatInfoFinderInfo];
	
    carbonPoint = ((FileInfo*)_catalogInfo.finderInfo)->location;
	
    return NSMakePoint(carbonPoint.h, carbonPoint.v);
}

- (BOOL)isInvisible;
{
    if (!_isValid)
        return NO;
	
    [self updateForFlags:kFSCatInfoFinderInfo];
	
    BOOL result = ((((FileInfo*)_catalogInfo.finderInfo)->finderFlags & kIsInvisible) != 0);
	
	return result;
}

- (BOOL)isCarbonAlias;
{
    if (!_isValid)
        return NO;
	
    if ([self isFile])
	{
		// not sure when Apple added this, but the alias bit is set for sym links also, let's check for that and return NO
		// we only return yet for classic carbon aliases
        if ([self isAliasBitSet])
			return ![self isSymbolicLink];
	}
	
    return NO;
}

- (BOOL)hasCustomIcon;
{
    if (!_isValid)
        return NO;
	
    [self updateForFlags:kFSCatInfoFinderInfo];
	
    return ((((FileInfo*)_catalogInfo.finderInfo)->finderFlags & kHasCustomIcon) != 0);
}

- (BOOL)isSymbolicLink;
{
    if (!_isValid)
        return NO;
	
    if ([self isFile])
        return S_ISLNK([self modeBits]);
	
    return NO;
}

- (UInt32)ownerID;
{
    FSPermissionInfo* permPtr;
	
    if (!_isValid)
        return 0;
	
    [self updateForFlags:kFSCatInfoPermissions];
	
    permPtr = (FSPermissionInfo*) &(_catalogInfo.permissions);
	
    return permPtr->userID;
}

- (NSString *)ownerName;
{
    if (!_isValid)
        return @"";
	
    return [[NTUsersAndGroups sharedInstance] userName:[self ownerID]];
}

- (UInt32)groupID;
{
    FSPermissionInfo* permPtr;
	
    if (!_isValid)
        return 0;
	
    [self updateForFlags:kFSCatInfoPermissions];
	
    permPtr = (FSPermissionInfo*) &(_catalogInfo.permissions);
	
    return permPtr->groupID;
}

- (NSString *)groupName;
{
    if (!_isValid)
        return @"";
	
    return [[NTUsersAndGroups sharedInstance] groupName:[self groupID]];
}

// not unique for volumes, they all return fsRtDirID
- (UInt32)nodeID;
{
    if (!_isValid)
        return 0;
	
    [self updateForFlags:kFSCatInfoNodeID];
	
    return _catalogInfo.nodeID;
}

- (UInt16)modeBits;
{
    FSPermissionInfo* permPtr;
	
    if (!_isValid)
        return 0;
	
    [self updateForFlags:kFSCatInfoPermissions];
	
    permPtr = (FSPermissionInfo*) &(_catalogInfo.permissions);
	
    return permPtr->mode;
}

- (UInt64)dataLogicalSize;
{
	if (!_isValid)
        return 0;
	
	[self updateForFlags:kFSCatInfoDataSizes];
	
	return _catalogInfo.dataLogicalSize;
}

- (UInt64)dataPhysicalSize;
{
	if (!_isValid)
        return 0;
	
	[self updateForFlags:kFSCatInfoDataSizes];
	
	return _catalogInfo.dataPhysicalSize;	
}

- (UInt64)rsrcLogicalSize;
{
	if (!_isValid)
        return 0;
	
	[self updateForFlags:kFSCatInfoRsrcSizes];
	
	return _catalogInfo.rsrcLogicalSize;		
}

- (UInt64)rsrcPhysicalSize;
{
	if (!_isValid)
        return 0;
	
	[self updateForFlags:kFSCatInfoRsrcSizes];
	
	return _catalogInfo.rsrcPhysicalSize;	
}

- (UInt8)sharingFlags;
{
    if (!_isValid)
        return 0;
	
    [self updateForFlags:kFSCatInfoSharingFlags];
	
    return _catalogInfo.sharingFlags;
}

- (BOOL)stillExists;
{	
    if (!_isValid)
        return NO;
	
    if (FSIsFSRefValid(&_ref))
		return YES;
    
    return NO;
}

- (BOOL)hasBeenModified;
{
	if (!mv_hasBeenModified)
		mv_hasBeenModified = [self checkHasBeenModified];
	
    return mv_hasBeenModified;
}

- (BOOL)hasBeenRenamed;
{
	if (!mHasBeenRenamed)
		mHasBeenRenamed = ![[self name] isEqualToString:[self nameWhenCreated]];
	
    return mHasBeenRenamed;
}	

// returns nil if no parent
- (NTFSRefObject*)parentFSRef;
{
    if (!_isValid)
        return nil;
	
	NTFSRefObject* result=nil;
    if (![self isVolume])
    {
        FSRef parentRef;
        OSErr err;
		
        err = FSGetCatalogInfo(&_ref, kFSCatInfoNone, NULL, NULL, NULL, &parentRef);
        if (!err)
			result = [NTFSRefObject refObject:&parentRef catalogInfo:nil bitmap:0 name:nil];
	}
	
    return result;
}

- (NSURL*)URL;
{
    NSURL* url=nil;
	
    if (!_isValid)
        return nil;
	
    CFURLRef cfURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &_ref);
    if (cfURL)
    {
        url = [[(NSURL*)cfURL retain] autorelease];
        CFRelease(cfURL);
    }
	
    return url;
}

// call this before you call catalogInfo if you want to make sure this info has been set
- (void)updateCatalogInfo:(FSCatalogInfoBitmap)bitmap;
{
    if (!_isValid)
        return;
	
    [self updateForFlags:bitmap];
}

- (FSCatalogInfo*)catalogInfo;
{
    if (!_isValid)
        return nil;
	
    return &_catalogInfo;
}

- (FSCatalogInfoBitmap)catalogInfoBitmap;
{
    if (!_isValid)
        return 0;
	
    return _catalogInfoBitmap;
}

- (BOOL)isParentOfFSRef:(const FSRef*)ref;  // used to determine if FSRef is contained by this directory
{
    BOOL result = NO;
    NTFSRefObject* parentRef = [NTFSRefObject refObject:ref catalogInfo:nil bitmap:0 name:nil];
	
    // see if the parent matches our directory    
    for (;;)
    {
        parentRef = [parentRef parentFSRef];
		
        if (parentRef && [parentRef isValid])
        {
            OSErr err = FSCompareFSRefs(&_ref, [parentRef ref]);
            if (err == noErr)
            {
                result = YES;
                break;
            }
            else if (err == diffVolErr) // if volume is different, bail out
                break;
        }
        else
            break;
    }
	
    return result;
}

@end

// =========================================================

@implementation NTFSRefObject (Private)

// force a fresh copy of the values
- (void)clearFlags:(FSCatalogInfoBitmap)flags
{
	_catalogInfoBitmap &= ~flags;
}

- (BOOL)flagsNeedUpdate:(FSCatalogInfoBitmap)flags
{
	return ((_catalogInfoBitmap & flags) != flags);
}

- (void)updateForFlags:(FSCatalogInfoBitmap)flags
{
    // if we already have gotten this information, don't do anything
    if ([self flagsNeedUpdate:flags])
    {
		// if we are going to hit the disk get the basics while we are at it to avoid future common bits
		flags |= kDefaultCatalogInfoBitmap;
		
        OSStatus err;
        FSCatalogInfoBitmap minimalBits = (flags & ~(_catalogInfoBitmap & flags));
		
		// for debugging	
		// [[self class] logFlags:minimalBits];
		
        _catalogInfoBitmap |= minimalBits;
        err = FSGetCatalogInfo(&_ref, minimalBits, &_catalogInfo, NULL, NULL, NULL);
    }
}

- (NSString*)description;
{
    NSMutableString* result;
    FSCatalogInfo catalogInfo;
    FSGetCatalogInfo(&_ref, kFSCatInfoGettableInfo, &catalogInfo, NULL, NULL, NULL);
    FSPermissionInfo* permPtr = (FSPermissionInfo*) &(catalogInfo.permissions);
	
    result = [NSMutableString string];
    [result appendString:[NSString stringWithFormat:@"directory: %@", [self isDirectory] ? @"YES": @"NO"]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"name: %@", [self name]]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"nodeID: %d", catalogInfo.nodeID]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"nodeFlags: %d", catalogInfo.nodeFlags]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"sharingFlags: %d", catalogInfo.sharingFlags]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"mode: %o", permPtr->mode]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"symlink: %@", S_ISLNK(permPtr->mode) ? @"YES": @"NO"]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"locked: %@", [self isLocked] ? @"YES": @"NO"]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"macAlias: %@", [self isCarbonAlias] ? @"YES": @"NO"]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"hasCustomIcon: %@", [self hasCustomIcon] ? @"YES": @"NO"]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"is invisible: %@", [self isInvisible] ? @"YES": @"NO"]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"owner: %@", [self ownerName]]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"group: %@", [self groupName]]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"url: %@", [[self URL] description]]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"modification date: %@", [[self modificationDate] description]]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"creation date: %@", [[self creationDate] description]]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"attribute date: %@", [[self attributeModificationDate] description]]];
    [result appendString:@"\n"];
    [result appendString:[NSString stringWithFormat:@"access date: %@", [[self accessDate] description]]];
    [result appendString:@"\n"];
	
    return result;
}

- (BOOL)checkHasBeenModified;
{
	BOOL hasBeenModified = NO;
	
	// must make sure we get fresh copies of the latest dates
	[self clearFlags:kFSCatInfoAttrMod | kFSCatInfoContentMod];
	
	NSDate *fileModDate = [self modificationDate];
	NSDate *fileAttrModDate = [self attributeModificationDate];
	
	// some volumes return 0 as the mod date, don't return modified otherwise it will always return modified
	if (fileModDate)
	{
		hasBeenModified = YES;
		
		if ([fileModDate compare:[self referenceDate]] != NSOrderedDescending)
		{
			if (fileAttrModDate)
			{
				if ([fileAttrModDate compare:[self referenceDate]] != NSOrderedDescending)
					hasBeenModified = NO;
			}
			else
				hasBeenModified = NO;
		}
		
		// ** special case **
		// must compare the current date with the fileModDate, if the filesModDate is in the future (for example if you get a file emailed from the finland)
		// you don't want to return modified, the file has not modified, it's date is just in the future
		if (hasBeenModified)
		{
			NSDate *now = [NSDate date];
			
			if ([fileModDate compare:now] == NSOrderedDescending)
				hasBeenModified = NO;
			
			if (hasBeenModified && fileAttrModDate)
			{
				if ([fileAttrModDate compare:now] == NSOrderedDescending)
					hasBeenModified = NO;
			}
		}
	}
	
	return hasBeenModified;
}

@end

@implementation NTFSRefObject (Utilities)

+ (BOOL)createFSRef:(FSRef*)outRef fromPath:(const UInt8 *)utf8Path followSymlink:(BOOL)followSymlink;
{
	OptionBits options = kFSPathMakeRefDefaultOptions;
	
	if (!followSymlink)
		options |= kFSPathMakeRefDoNotFollowLeafSymlink;
	
	OSStatus status =  FSPathMakeRefWithOptions(utf8Path, options, outRef, nil);
	
	return (status == noErr);
}

+ (FSRef*)bootFSRef;
{
	static BOOL initialized=NO;
	static FSRef bootFSRef;
	
	if (!initialized)
	{
		initialized = YES;
		
		[self createFSRef:&bootFSRef fromPath:(const UInt8 *)"/" followSymlink:NO];
 	}
	
	return &bootFSRef;
}

+ (void)logFlag:(FSCatalogInfoBitmap)flag;
{
	switch (flag)
	{
		case kFSCatInfoTextEncoding: 
			NSLog(@"kFSCatInfoTextEncoding"); break; 
		case kFSCatInfoNodeFlags: 
			NSLog(@"kFSCatInfoNodeFlags"); break;      
		case kFSCatInfoVolume: 
			NSLog(@"kFSCatInfoVolume"); break;        
		case kFSCatInfoParentDirID: 
			NSLog(@"kFSCatInfoParentDirID"); break;       
		case kFSCatInfoNodeID: 
			NSLog(@"kFSCatInfoNodeID"); break;          
		case kFSCatInfoCreateDate: 
			NSLog(@"kFSCatInfoCreateDate"); break;        
		case kFSCatInfoContentMod: 
			NSLog(@"kFSCatInfoContentMod"); break;
		case kFSCatInfoAttrMod: 
			NSLog(@"kFSCatInfoAttrMod"); break;
		case kFSCatInfoAccessDate: 
			NSLog(@"kFSCatInfoAccessDate"); break;
		case kFSCatInfoBackupDate: 
			NSLog(@"kFSCatInfoBackupDate"); break;
		case kFSCatInfoPermissions: 
			NSLog(@"kFSCatInfoPermissions"); break; 
		case kFSCatInfoFinderInfo: 
			NSLog(@"kFSCatInfoFinderInfo"); break;        
		case kFSCatInfoFinderXInfo: 
			NSLog(@"kFSCatInfoFinderXInfo"); break;       
		case kFSCatInfoValence: 
			NSLog(@"kFSCatInfoValence"); break;          
		case kFSCatInfoDataSizes: 
			NSLog(@"kFSCatInfoDataSizes"); break;      
		case kFSCatInfoRsrcSizes: 
			NSLog(@"kFSCatInfoRsrcSizes"); break;     
		case kFSCatInfoSharingFlags: 
			NSLog(@"kFSCatInfoSharingFlags"); break;   
		case kFSCatInfoUserPrivs: 
			NSLog(@"kFSCatInfoUserPrivs"); break;        
		case kFSCatInfoUserAccess: 
			NSLog(@"kFSCatInfoUserAccess"); break;       
		case kFSCatInfoSetOwnership: 
			NSLog(@"kFSCatInfoSetOwnership"); break; 
		case kFSCatInfoFSFileSecurityRef: 
			NSLog(@"kFSCatInfoFSFileSecurityRef"); break;  
		default:
			break;
	}
}

+ (void)logFlags:(FSCatalogInfoBitmap)flags;
{			
	[self logFlag:(kFSCatInfoTextEncoding & flags)];
	[self logFlag:(kFSCatInfoNodeFlags & flags)];
	[self logFlag:(kFSCatInfoVolume & flags)];
	[self logFlag:(kFSCatInfoParentDirID & flags)];
	[self logFlag:(kFSCatInfoNodeID & flags)];
	[self logFlag:(kFSCatInfoCreateDate & flags)];
	[self logFlag:(kFSCatInfoContentMod & flags)];
	[self logFlag:(kFSCatInfoAttrMod & flags)];
	[self logFlag:(kFSCatInfoAccessDate & flags)];
	[self logFlag:(kFSCatInfoBackupDate & flags)];
	[self logFlag:(kFSCatInfoPermissions & flags)];
	[self logFlag:(kFSCatInfoFinderInfo & flags)];
	[self logFlag:(kFSCatInfoFinderXInfo & flags)];
	[self logFlag:(kFSCatInfoValence & flags)];
	[self logFlag:(kFSCatInfoDataSizes & flags)];
	[self logFlag:(kFSCatInfoRsrcSizes & flags)];
	[self logFlag:(kFSCatInfoSharingFlags & flags)];
	[self logFlag:(kFSCatInfoUserPrivs & flags)];
	[self logFlag:(kFSCatInfoUserAccess & flags)];
	[self logFlag:(kFSCatInfoSetOwnership & flags)];
	[self logFlag:(kFSCatInfoFSFileSecurityRef & flags)];
}

- (BOOL)isParentOfRefPath:(NSArray*)refPath;  // used to determine if FSRef is contained by this directory
{
	BOOL result = NO;
	NTFSRefObject* refObj;
	
	for (refObj in refPath)
	{			
		if (refObj && [refObj isValid])
		{
			OSErr err = FSCompareFSRefs(&_ref, [refObj ref]);
			if (err == noErr)
			{
				result = YES;
				break;
			}
			else if (err == diffVolErr) // if volume is different, bail out
				break;
		}
		else
			break;
	}
	
	return result;	
}

@end
