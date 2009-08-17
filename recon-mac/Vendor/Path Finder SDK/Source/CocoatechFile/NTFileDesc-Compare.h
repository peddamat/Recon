//
//  NTFileDesc-Compare.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/13/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTFileDesc.h"

@interface NTFileDesc (Compare)

- (NSComparisonResult)compareByDisplayName:(NTFileDesc *)fsi;
- (NSComparisonResult)compareByName:(NTFileDesc *)fsi;
- (NSComparisonResult)compareByVolumeType:(NTFileDesc *)right;
- (NSComparisonResult)compareByModificationDate:(NTFileDesc *)fsi;

- (BOOL)isEqualToDesc:(NTFileDesc*)right;
- (BOOL)isEqual:(NTFileDesc*)right;

// this is a stricter comparison.  Checks mod dates and name
- (BOOL)isEqualTo:(NTFileDesc*)right;

@end

@interface NTFileDesc (SortDescriptors)

+ (NSArray*)volumeTypeSortDescriptors;

@end

@interface NSArray (NTFileDescAdditions)
- (BOOL)isEqualToDescs:(NSArray*)inRightDescs
			matchOrder:(BOOL)matchOrder;
@end
