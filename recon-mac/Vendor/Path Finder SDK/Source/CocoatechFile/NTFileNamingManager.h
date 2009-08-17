//
//  NTFileNamingManager.h
//  CocoatechFile
//
//  Created by sgehrman on Sun Aug 12 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// When you have async file commands happening, you can't just look at the contents of the disk
// to determine if a file name is unused.  For example, you could start a thread that duplicates a folder named
// "xyz", the thread looks at the disk and sees that "xyz copy" is a valid name to give to duplicate.  Before that 
// thread has a chance to create the new folder, you issue a rename or even another duplicate command.  There is a chance that
// the code could pick "xyz copy" as a valid name and then one of the two operations would fail.
// The purpose of this code is keep a list of filenames currently being used by the program.  Any code dealing with
// creating, renaming, or moving files should consult this manager to see if the name has been reserved.

@interface NTFileNamingManager : NSObject {
    NSMutableArray* _nameReserve;
}

+ (NTFileNamingManager*)sharedInstance;

// returns a unique name
- (NSString*)uniqueName:(NSString*)path with:(NSString*)with;
- (BOOL)isUnique:(NSString*)path;

// you must call releaseName after 
// the real file has been created, or the user cancels the operation
- (void)reserveName:(NSString*)path;
- (void)releaseName:(NSString*)path;

@end
