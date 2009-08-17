//
//  NTFilePreflightTests.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 5/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTFilePreflightTests : NSObject {
}

// checks if valid, and warns user if it's not
+ (BOOL)isSourceValid:(NTFileDesc*)source;

	// checks if valid, and if a directory, and if writable, and warns user if not
+ (BOOL)isDestinationValid:(NTFileDesc*)source;

+ (BOOL)isSource:(NTFileDesc*)source onSameVolumeAsDestination:(NTFileDesc*)destination;
+ (BOOL)isSource:(NTFileDesc*)source equalToDestination:(NTFileDesc*)destination;

+ (BOOL)isDestination:(NTFileDesc*)destination insideTheSource:(NTFileDesc*)source;

	// we need to ask this if we are going to replace a directory (delete it) with the source directory
	// if the source was inside this directory, it would be lost
+ (BOOL)isSource:(NTFileDesc*)source insideTheDirectory:(NTFileDesc*)directory;

	// returns a modified array, removes any items that are located within one of the other items
	// good for move, and delete calls since we can't delete/move a child if we've already deleted/moved it's parent
+ (NSArray*)removeChildItemsFromSources:(NSArray*)sources;
@end
