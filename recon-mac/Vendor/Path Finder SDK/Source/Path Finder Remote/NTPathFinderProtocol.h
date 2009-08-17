//
//  NTPathFinderProtocol.h
//  Path Finder Remote
//
//  Created by Steve Gehrman on 8/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPathFinderListenerName @"Path FinderListener"
#define kBackgroundAppLaunchedNotificationName @"kPathFinderBackgroundAppLaunchedNotificationName"
#define kBackgroundAppName @"Path Finder"

typedef enum NTRevealPathBehavior
{
	kDefaultRevealBehavior,  // uses whatever the default is in the host app
	
	kReuseWindowRevealBehavior,
	kNewWindowRevealBehavior,
	kNewTabRevealBehavior
	
} NTRevealPathBehavior;

@protocol NTPathFinderProtocol <NSObject>

- (oneway void)activate; // brings Path Finder to front

	// ** information
- (bycopy NSArray*)selection;
- (bycopy NSArray*)volumes;
- (bycopy NSArray*)directoryListing:(oneway NSString*)path visibleItemsOnly:(BOOL)visibleItemsOnly;

	// front most window's current displayed directory
- (bycopy NSString*)currentDirectory;  

	// ** commands
- (oneway void)revealPaths:(oneway NSArray *)paths behavior:(oneway NTRevealPathBehavior)behavior;
- (oneway void)selectPaths:(oneway NSArray *)paths byExtendingSelection:(oneway BOOL)extend;

- (oneway void)showGetInfo:(oneway NSString*)path;
- (oneway void)ejectVolume:(oneway NSString*)path;
- (oneway void)moveToTrash:(oneway NSString*)path;

	// destination can include desired filename or just destination folder, or nil to perform the copy or make alias in the same folder, a copy with a nil destination is the same as duplicate
- (oneway void)copy:(oneway NSString*)path destination:(oneway NSString*)destination;
- (oneway void)duplicate:(oneway NSString*)path;
- (oneway void)move:(oneway NSString*)path destination:(oneway NSString*)destination;
- (oneway void)makeAlias:(oneway NSString*)path destination:(oneway NSString*)destination;

- (oneway void)rename:(oneway NSString*)path newName:(NSString*)newName;

@end
