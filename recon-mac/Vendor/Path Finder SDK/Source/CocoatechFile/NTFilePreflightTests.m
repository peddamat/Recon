//
//  NTFilePreflightTests.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 5/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTFilePreflightTests.h"

@implementation NTFilePreflightTests

// checks if valid, and warns user if it's not
+ (BOOL)isSourceValid:(NTFileDesc*)source;
{
	if (![source isValid])
	{
		NSString *message = [source path];
		message = [message stringByAppendingString:[NTLocalizedString localize:@" was not found." table:@"CocoaTechFoundation"]];
		
		NSLog(@"-[%@ %@] %@", [self className], NSStringFromSelector(_cmd), message);
		
		return NO;
	}
	
    return YES;
}

+ (BOOL)isDestinationValid:(NTFileDesc*)destination
{		
    // the dest path valid and a directory?
    if (![destination isValid] || ![destination isDirectory])
    {
        NSString* message = [[destination path] stringByAppendingString:[NTLocalizedString localize:@" was not found." table:@"CocoaTechFoundation"]];
		
		NSLog(@"-[%@ %@] %@", [self className], NSStringFromSelector(_cmd), message);

        return NO;
    }
    
	// is destination writable?
	if (![destination isWritable])
    {
        NSString* message = [NSString stringWithFormat:[NTLocalizedString localize:@"You don't have write permission at \"%@\"" table:@"CocoaTechFoundation"], [destination path]];

		NSLog(@"-[%@ %@] %@", [self className], NSStringFromSelector(_cmd), message);

        return NO;
    }

    return YES;
}

+ (BOOL)isSource:(NTFileDesc*)source onSameVolumeAsDestination:(NTFileDesc*)destination;
{
	if ([source volumeRefNum] == [destination volumeRefNum])
		return YES;
	
    return NO;
}

+ (BOOL)isSource:(NTFileDesc*)source equalToDestination:(NTFileDesc*)destination;
{
	return [source isEqualToDesc:destination];
}

+ (BOOL)isDestination:(NTFileDesc*)destination insideTheSource:(NTFileDesc*)source;
{
	return [source isParentOfDesc:destination];
}

// we need to ask this if we are going to replace a directory with the source directory
// the source would be deleted before the copy could happen and all data would be lost
+ (BOOL)isSource:(NTFileDesc*)source insideTheDirectory:(NTFileDesc*)directory;
{
	return [directory isParentOfDesc:source];
}

// returns a modified array, removes any items that are located within one of the other items
// good for move, and delete calls since we can't delete/move a child if we've already deleted/moved it's parent
+ (NSArray*)removeChildItemsFromSources:(NSArray*)sources;
{
	NSMutableArray *resultArray = [NSMutableArray array];
	NSMutableArray* folders = [NSMutableArray array];
    NTFileDesc *desc, *folder;
	
    // first get the folders in the list
	for (desc in sources)
	{		
        if ([desc isDirectory])
            [folders addObject:desc];
    }
	
	for (desc in sources)
	{
		NSEnumerator *folderEnumerator = [folders objectEnumerator];
		BOOL add = YES;
		
		NSArray *refPath = [desc FSRefPath:NO];
		
		while (folder = [folderEnumerator nextObject])
		{
			if ([folder isParentOfRefPath:refPath])
			{
				add = NO;
				break;
			}
		}
		
		if (add)
			[resultArray addObject:desc];
	}
		
	return resultArray;
}

@end
