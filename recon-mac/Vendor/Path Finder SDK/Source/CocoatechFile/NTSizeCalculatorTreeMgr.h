//
//  NTSizeCalculatorTreeMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTSizeCalculatorTreeMgr : NTSingletonObject
{
	NSMutableDictionary* trees;  // one for each volume
}

@property (retain) NSMutableDictionary* trees;

- (void)addFolders:(NSArray*)theFolders;
- (void)removeFolders:(NSArray*)theFolders;

// debugging only
- (void)debugTreeNodeForFolder:(NTFileDesc*)folder;

@end
