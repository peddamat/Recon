//
//  NTPathFinderConnection.h
//  Path Finder Remote
//
//  Created by Steve Gehrman on 8/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTPathFinderProtocol.h"

#define kNTNowConnectedtoBackgroundApplication @"NTNowConnectedtoBackgroundApplication"

// this handles communicating with our background application

@interface NTPathFinderConnection : NSObject
{
    NSConnection* _connection;
    NSDistantObject<NTPathFinderProtocol> *_distantObject;
}

- (void)connect;
- (void)activate; // brings app to front

	// ** information
- (NSArray*)selection;
- (NSArray*)volumes;
- (NSArray*)directoryListing:(NSString*)path visibleItemsOnly:(BOOL)visibleItemsOnly;

	// front most window's current displayed directory
- (NSString*)currentDirectory;  

	// ** commands
- (void)revealPaths:(NSArray*)path behavior:(NTRevealPathBehavior)behavior;
- (void)selectPaths:(NSArray*)path byExtendingSelection:(BOOL)extend;

- (void)showGetInfo:(NSString*)path;
- (void)ejectVolume:(NSString*)path;
- (void)moveToTrash:(NSString*)path;

	// destination can include desired filename or just destination folder, or nil in the case of copy and makeAlias
- (void)copy:(NSString*)path destination:(NSString*)destination;
- (void)move:(NSString*)path destination:(NSString*)destination;
- (void)makeAlias:(NSString*)path destination:(NSString*)destination;
- (void)rename:(NSString*)path newName:(NSString*)newName;
- (void)duplicate:(NSString*)path;

@end
