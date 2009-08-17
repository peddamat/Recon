//
//  NTFileDesc-Private.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 10/13/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTFileDesc.h"

@interface NTFileDesc (Private)
- (NTFileDesc*)resolvedDesc:(BOOL)resolveIfServerAlias;
- (NSString*)carbonVersionString:(BOOL)shortVersion;
- (void)setAliasDesc:(NTFileDesc*)desc; // if we were resolved from an alias, this is the original alias file

+ (NTFileDesc*)resolveAlias:(NTFileDesc*)desc resolveIfServerAlias:(BOOL)resolveIfServerAlias isServerAlias:(BOOL*)isServerAlias;

	// in Tiger, .hidden was removed, but there were a few files that were not correctly hidden
	// hack that might be removed in future OSes
- (BOOL)isUnixFileThatShouldBeHidden;
- (NSString*)volumeInfoString;

- (void)initializeSizeInfo;
@end
