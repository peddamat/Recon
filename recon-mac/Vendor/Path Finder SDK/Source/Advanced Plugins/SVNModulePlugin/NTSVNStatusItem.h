//
//  NTSVNStatusItem.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum NTSVNStatusItemStatus
{
	kNoFileStatus=1,
	
	kNewFileStatus,
	kModifiedFileStatus,
	kMissingFileStatus,
	kConflictFileStatus,
	kObstructedFileStatus,
	kUnversionedFileStatus,
	kIgnoredFileStatus,
	kDeletedFileStatus,
	kAddedFileStatus,
	kMergedFileStatus,
	kReplacedFileStatus,

} NTSVNStatusItemStatus;

@interface NTSVNStatusItem : NSObject 
{		
	NSDictionary* mDictionary;
	NSString* mHTML;
	
	NTSVNStatusItemStatus mStatus;
}

+ (NTSVNStatusItem*)item:(NSDictionary*)info;

// convert xml to an array of items
+ (NSArray*)xmlToItems:(NSString*)xml;

- (NSString *)HTML;

// extracted from info dictionary
- (NSString *)relativePath;

- (NTSVNStatusItemStatus)status;
- (void)setStatus:(NTSVNStatusItemStatus)theStatus;

@end
