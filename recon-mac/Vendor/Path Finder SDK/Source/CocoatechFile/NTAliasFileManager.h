//
//  NTAliasFileManager.h
//  CocoatechFile
//
//  Created by sgehrman on Fri Jul 13 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTFileDesc;

@interface NTAliasFileManager : NSObject 
{
}

+ (NTFileDesc*)createAliasFile:(NTFileDesc*)fileDesc atPath:(NSString*)destPath;
+ (NTFileDesc*)createPathFinderAliasFile:(NTFileDesc*)desc atPath:(NSString*)destPath;

    // outIsServerAlias can be nil if you don't care
+ (NTFileDesc*)resolveAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias;
+ (NTFileDesc*)resolvePathFinderAliasFile:(NTFileDesc*)desc resolveServer:(BOOL)resolveServer outIsServerAlias:(BOOL*)outIsServerAlias;

// for funky network symlinks
+ (NTFileDesc*)resolveNetworkAliasFile:(NTFileDesc*)desc;

	// alias handle becomes owned by the Resource manager, so don't dispose yourself
+ (BOOL)addAliasResource:(AliasHandle)alias toFile:(FSRef*)ref dataFork:(BOOL)dataFork;

// updates the custom icon and type/creator for an alias file
+ (void)setupAliasFile:(NTFileDesc*)aliasFile forDesc:(NTFileDesc*)desc;

@end
