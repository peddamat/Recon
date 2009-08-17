//
//  NTPathFinderRemote.h
//  Path Finder Remote
//
//  Created by Steve Gehrman on 8/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTPathFinderProtocol.h"
// 
// create an instance of this object to control Path Finder remotely
//

typedef enum
{
	kPFR_Connected,
	kPFR_Disconnected
} NTPathFinderConnectionStatus;

// delegate protocol
@protocol NTPathFinderRemoteDelegateProtocol <NSObject>
- (void)PFR_connectionStatus:(NTPathFinderConnectionStatus)status;  // called after a call to connect or called if connection is dropped
@end

@class NTPathFinderConnection;

@interface NTPathFinderRemote : NSObject
{
	id<NTPathFinderRemoteDelegateProtocol> _delegate;
	
	NTPathFinderConnection *_connection;
	BOOL mConnected;
}

// delegate is not retained
- (id)initWithDelegate:(id<NTPathFinderRemoteDelegateProtocol>)delegate;

	// must make connection before doing anything else
- (void)connect;
	// launches Path Finder if not running and makes a distributed object connection
	// sends a PFR_connectionStatus when successfully connected

- (BOOL)connected;

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

