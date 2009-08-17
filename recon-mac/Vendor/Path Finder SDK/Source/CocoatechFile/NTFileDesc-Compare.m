//
//  NTFileDesc-Compare.m
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/13/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc-Compare.h"

@interface NTFileDesc (ComparePrivate)
// used for sorting volumes
- (int)volumeSortRank:(NTFileDesc*)desc;
@end

@implementation NTFileDesc (Compare)

- (NSComparisonResult)compareByDisplayName:(NTFileDesc *)fsi
{
    return ([[self displayName] caseInsensitiveCompare:[fsi displayName]]);
}

- (NSComparisonResult)compareByModificationDate:(NTFileDesc *)fsi;
{
	return ([[self modificationDate] compare:[fsi modificationDate]]);
}

- (NSComparisonResult)compareByName:(NTFileDesc *)fsi; // use for sorting an array of descs
{
	// name is not cached since it could change, but for sorting, it's too slow to fetch the name each time
    return ([[self nameWhenCreated] caseInsensitiveCompare:[fsi nameWhenCreated]]);
}

- (NSComparisonResult)compareByDate:(NTFileDesc *)fsi; // use for sorting an array of descs
{
    return ([[self modificationDate] compare:[fsi modificationDate]]);
}

- (NSComparisonResult)compareByVolumeType:(NTFileDesc *)right;
{
    NSComparisonResult result;
    int myRank, theirRank;
    
    myRank = [self volumeSortRank:self];
    theirRank = [self volumeSortRank:right];
    
    if (myRank < theirRank)
        result = NSOrderedAscending;
    else if (myRank > theirRank)
        result = NSOrderedDescending;
    else
        result = NSOrderedSame;  // this will cause the next sortDescriptor to look at it
    
    return result;
}

- (BOOL)isEqual:(NTFileDesc*)right;
{
	if (self == right)
		return YES;

    if ([right isKindOfClass:[NTFileDesc class]])
        return [self isEqualToDesc:right];
    
    return NO;
}

// just checks if the FSRefs are the same
// this is better than checking paths since paths can be different if they contain symlinks or aliases, but refer to the same item
- (BOOL)isEqualToDesc:(NTFileDesc*)right;
{
	if (self == right)
		return YES;
	
    // both must be valid
    if ([self isValid] && [right isValid])
    {
        if ([self isComputer] && [right isComputer])
            return YES;
		else if ([self isComputer] || [right isComputer])
			return NO;
        else
            return (FSCompareFSRefs([self FSRefPtr], [right FSRefPtr]) == noErr);
    }
    else if (![self isValid] && ![right isValid])
        return YES;
    
    return NO;
}

- (BOOL)isEqualTo:(NTFileDesc*)right;
{
	if (self == right)
		return YES;

    BOOL result=NO;
	
    // both must be valid
    if ([self isValid] && [right isValid])
    {
        result = [self isEqualToDesc:right];
		
        // compare modification dates
        if (result)
            result = ([[self modificationDate] compare:[right modificationDate]] == NSOrderedSame);
		
        // compare attributeModificationDate dates
        if (result)
            result = ([[self attributeModificationDate] compare:[right attributeModificationDate]] == NSOrderedSame);

		// compare nameWhenCreated, a file can be renamed and neither date changes
        if (result)
            result = [[self nameWhenCreated] isEqualToString:[right nameWhenCreated]];
	}
	
    // or both could be invalid
    if (![self isValid] && ![right isValid])
        result = YES;
	
    return result;
}

@end

@implementation NTFileDesc (ComparePrivate)

// used for sorting volumes
- (int)volumeSortRank:(NTFileDesc*)desc;
{
    int rank = 10;
    
	if ([desc isBootVolume])
        rank = 0;
    else
    {
        if ([desc isVolume])
        {
            rank = 1;
            
			// don't add "else" clauses, not all externals are ejectable, we want ejectable to be last
            if ([desc isExternal])
                rank = 2;
			
			if ([desc isNetwork])
                rank = 3;
			
			if ([desc isEjectable])
                rank = 4;
        }
    }
    
    return rank;
}

@end

@implementation NTFileDesc (SortDescriptors)

// this is for compatibility with sortDescriptors.  we need a key, so this is our dummy key
- (id)sortDescriptorKey;
{
	return self;
}

+ (NSArray*)volumeTypeSortDescriptors;
{
	NSArray *sd = [NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"sortDescriptorKey" ascending:YES selector:@selector(compareByVolumeType:)] autorelease],
		[[[NSSortDescriptor alloc] initWithKey:@"sortDescriptorKey" ascending:YES selector:@selector(compareByDisplayName:)] autorelease],
		nil];
	
	return sd;
}

@end

@implementation NSArray (NTFileDescAdditions)

- (BOOL)isEqualToDescs:(NSArray*)inRightDescs
			matchOrder:(BOOL)matchOrder;
{
	NTFileDesc *left, *right;

	if ([self count] != [inRightDescs count])
		return NO;
		
	if (matchOrder)
	{
		int i, cnt = [self count];

		// same items, same order?
		for (i=0;i<cnt;i++)
		{			
			left = [self objectAtIndex:i];
			right = [inRightDescs objectAtIndex:i];
			
			if (left != right)
			{
				if (![left isEqualToDesc:right])
					return NO;
			}
		}		
	}
	else
	{
		NSMutableArray* rightDescs = [NSMutableArray arrayWithArray:inRightDescs];
		NSEnumerator *enumerator = [self objectEnumerator];
		
		while (left = [enumerator nextObject])
		{
			BOOL found=NO;
			
			int i, cnt = [rightDescs count];
			for (i=0;i<cnt;i++)
			{
				right = [rightDescs objectAtIndex:i];
				
				if ([left isEqualToDesc:right])
				{				
					// remove so next search will be faster
					[rightDescs removeObjectAtIndex:i];
					
					found = YES;
					break;
				}
			}
			
			if (!found)
				return NO;
		}
	}
	
	return YES;
}


@end



