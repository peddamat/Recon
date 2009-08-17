//
//  NTFSSize.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 3/4/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTFSSize.h"

@implementation NTFSSize

@synthesize desc;
@synthesize contentSize;
@synthesize subfolderSize;
@synthesize children;

// dynamic
@dynamic size;
@dynamic physicalSize;
@dynamic valence;

+ (NTFSSize*)size:(NTFileDesc*)theDesc
	  contentSize:(NTFSSizeSpec*)theContentSize 
	subfolderSize:(NTFSSizeSpec*)theSubfolderSize
		 children:(NSArray*)theChildren;
{
    NTFSSize *result = 	[[NTFSSize alloc] init];
	
	result.desc = theDesc;
	result.contentSize = theContentSize;
	result.subfolderSize = theSubfolderSize; 
	result.children = theChildren; 
	
	return [result autorelease];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	self.desc = nil;
	self.contentSize = nil;
	self.subfolderSize = nil; 
	self.children = nil; 

    [super dealloc];
}

//---------------------------------------------------------- 
//  size 
//---------------------------------------------------------- 
- (UInt64)size
{
	UInt64 result=self.contentSize.size + self.subfolderSize.size;
	for (NTFSSize *aSize in self.children)
		result += aSize.size;
	
	return result;
}

//---------------------------------------------------------- 
//  physicalSize 
//---------------------------------------------------------- 
- (UInt64)physicalSize
{
	UInt64 result=self.contentSize.physicalSize + self.subfolderSize.physicalSize;
	for (NTFSSize *aSize in self.children)
		result += aSize.physicalSize;
	
	return result;
}

//---------------------------------------------------------- 
//  valence 
//---------------------------------------------------------- 
- (UInt64)valence
{
	UInt64 result=self.contentSize.valence + self.subfolderSize.valence;
	for (NTFSSize *aSize in self.children)
		result += aSize.valence;
	
	return result;
}

- (NSString*)description;
{
	return [NSString stringWithFormat:@"(s:%u:%u:%u)", 
			self.size, 
			self.valence, 
			self.physicalSize];
}

- (BOOL)isEqualToSize:(NTFSSize*)right;
{
	if ((self.size == right.size) && 
		(self.physicalSize == right.physicalSize) &&
		(self.valence == right.valence))
		return YES;
	
	return NO;
}

- (NSSet*)childNodeIDs;  // node IDs of direct children (NSNumber for nodeID of folder desc)
{
	NSMutableSet* result = [NSMutableSet set];
	
	for (NTFSSize* child in self.children)
		[result addObject:[NSNumber numberWithUnsignedInt:[child.desc nodeID]]];
	
	return result;
}

- (NTFSSize*)sizeByReplacingChildren:(NSArray*)theChildren;
{
	NTFSSize *result = 	[[NTFSSize alloc] init];
	
	// copy over values
	result.desc = self.desc;
	result.contentSize = self.contentSize;
	result.subfolderSize = self.subfolderSize; 
	
	// but add the new children
	result.children = theChildren; 
	
	return [result autorelease];
}

@end

// =======================================================================================
// =======================================================================================

@implementation NTFSSizeSpec

@synthesize size;
@synthesize physicalSize;
@synthesize valence;

+ (NTFSSizeSpec*)sizeSpec:(UInt64)theSize 
			 physicalSize:(UInt64)thePhysicalSize
				  valence:(UInt64)theValence;
{
	NTFSSizeSpec* result = [[NTFSSizeSpec alloc] init];
	
	result.size = theSize; 
	result.physicalSize = thePhysicalSize; 
	result.valence = theValence; 
	
	return [result autorelease];
}

+ (NTFSSizeSpec*)sizeSpec:(NTFSSize*)theSize
{
	return [NTFSSizeSpec sizeSpec:theSize.size physicalSize:theSize.physicalSize valence:theSize.valence];
}

- (NTFSSizeSpec*)sizeByAddingSizeSpec:(NTFSSizeSpec*)theSize;
{
	NTFSSizeSpec *result = [NTFSSizeSpec sizeSpec:self.size physicalSize:self.physicalSize valence:self.valence];
	
	result.size += theSize.size;
	result.physicalSize += theSize.physicalSize;
	result.valence += theSize.valence;
	
	return result; // already autoreleased		
}

- (NTFSSizeSpec*)sizeByAddingSize:(NTFSSize*)theSize;
{
	NTFSSizeSpec *result = [NTFSSizeSpec sizeSpec:self.size physicalSize:self.physicalSize valence:self.valence];
	
	result.size += theSize.size;
	result.physicalSize += theSize.physicalSize;
	result.valence += theSize.valence;
	
	return result; // already autoreleased		
}

@end

