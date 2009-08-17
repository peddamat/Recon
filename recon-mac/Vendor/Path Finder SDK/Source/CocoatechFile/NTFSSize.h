//
//  NTFSSize.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 3/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFSSizeSpec;

@interface NTFSSize : NSObject
{
	NTFileDesc* desc;
	
	// we hold the content and subfolders separately
	// if folder changes, we can reuse the subfolder sizes to avoid a recalc
	NTFSSizeSpec *contentSize;
	NTFSSizeSpec *subfolderSize;
	
	// array of dependent NTFSSize objects
	NSArray* children;
}

@property (retain) NTFileDesc* desc;
@property (retain) NTFSSizeSpec* contentSize;
@property (retain) NTFSSizeSpec* subfolderSize;
@property (retain) NSArray* children;

// dynamic, a function of the content and subfolders
@property (readonly, assign) UInt64 size;
@property (readonly, assign) UInt64 physicalSize;
@property (readonly, assign) UInt64 valence;

+ (NTFSSize*)size:(NTFileDesc*)theDesc
	  contentSize:(NTFSSizeSpec*)theContentSize 
	subfolderSize:(NTFSSizeSpec*)theSubfolderSize
		 children:(NSArray*)theChildren;

- (BOOL)isEqualToSize:(NTFSSize*)right;

// used to help recreate an existing FSSize with updated children
- (NSSet*)childNodeIDs;  // node IDs of direct children (NSNumber for nodeID of folder desc)
- (NTFSSize*)sizeByReplacingChildren:(NSArray*)theChildren;
@end

// ==================================================================
// ==================================================================

@interface NTFSSizeSpec : NSObject
{
	UInt64 size;
    UInt64 physicalSize;
    UInt64 valence;	
}

+ (NTFSSizeSpec*)sizeSpec:(UInt64)theSize 
			 physicalSize:(UInt64)thePhysicalSize
				  valence:(UInt64)theValence;

+ (NTFSSizeSpec*)sizeSpec:(NTFSSize*)theSize;
- (NTFSSizeSpec*)sizeByAddingSizeSpec:(NTFSSizeSpec*)size;
- (NTFSSizeSpec*)sizeByAddingSize:(NTFSSize*)size;

@property (assign) UInt64 size;
@property (assign) UInt64 physicalSize;
@property (assign) UInt64 valence;

@end
