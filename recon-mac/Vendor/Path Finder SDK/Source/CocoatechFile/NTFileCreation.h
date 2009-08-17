//
//  NTFileCreation.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 5/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
    NTCarbonAliasType,
    NTSymlinkType,
    NTPathFinderAliasType
} NTAliasType;

@interface NTFileCreation : NSObject
{
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// creating files and folders

// pass 0 for permmissions for the default
+ (NTFileDesc*)newFolder:(NSString*)path
	  permissions:(unsigned)permissions;

+ (NTFileDesc*)newFile:(NSString*)path
	permissions:(unsigned)permissions;

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// creating aliases, symlinks and PF aliases

	// creates a unique name automatically
+ (NTFileDesc*)makeAlias:(NTFileDesc*)source
	  inDirectory:(NTFileDesc*)directory  // can be nil
		aliasType:(NTAliasType)type; 

	// uses a specific name, if it conflicts with an existing name, it makes a unique name
+ (NTFileDesc*)makeAlias:(NTFileDesc*)source
	  inDirectory:(NTFileDesc*)directory // can be nil
		aliasType:(NTAliasType)type
		 withName:(NSString*)name;  // can be nil
@end
