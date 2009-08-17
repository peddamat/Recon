//
//  NTFileRep.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 11/30/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import "NTFileRep.h"

// represents a file.  Used for restoring selection.

@implementation NTFileRep

@synthesize nodeID, volumeRefNum, isVolume;
@synthesize displayName;

+ (NSArray*)reps:(NSArray*)theDescs;
{
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[theDescs count]];
	
	for (NTFileDesc* theDesc in theDescs)
		[result addObject:[NTFileRep rep:theDesc]];
	
	return result;
}

+ (NTFileRep*)rep:(NTFileDesc*)theDesc;
{
	NTFileRep* result = [[NTFileRep alloc] init];
	
	result.nodeID = [theDesc nodeID];
	result.displayName = [theDesc displayName];
	
	// volumes return fsRtDirID for nodeID, so it's not unique
	result.isVolume = [theDesc isVolume];
	if (result.isVolume)
		result.volumeRefNum = [theDesc volumeRefNum];		
	
	return [result autorelease];
}

- (id)initWithCoder:(NSCoder *)coder 
{
	if (self = [self init])
    {			
		self.nodeID = [coder decodeInt32ForKey:@"nodeID"];
		self.volumeRefNum = [coder decodeInt32ForKey:@"volumeRefNum"];
		self.isVolume = [coder decodeBoolForKey:@"isVolume"];
		self.displayName = [coder decodeObjectForKey:@"displayName"];
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder 
{	
	[coder encodeInt32:self.nodeID forKey:@"nodeID"];
	[coder encodeInt32:self.volumeRefNum forKey:@"volumeRefNum"];
	[coder encodeBool:self.isVolume forKey:@"isVolume"];
    [coder encodeObject:self.displayName forKey:@"displayName"];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void) dealloc
{
    self.displayName = nil;
    [super dealloc];
}

// typically you would first try nodeID since that handles renamed files
- (BOOL)matchesNodeID:(NTFileDesc*)theDesc;
{	
	if (self.isVolume)
	{
		if ([theDesc isVolume])
			return (self.volumeRefNum == [theDesc volumeRefNum]);
	}
	else
		return (self.nodeID == [theDesc nodeID]);
	
	return NO;
}

// if not found by nodeID, it might have been a safe saved file, so find a matching displayName
- (BOOL)matchesDisplayName:(NTFileDesc*)theDesc;
{	
	return [[theDesc displayName] isEqualToString:self.displayName];
}

@end
