//
//  NTPathFinderRemote.m
//  Path Finder Remote
//
//  Created by Steve Gehrman on 8/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTPathFinderRemote.h"
#import "NTPathFinderConnection.h"

@interface NTPathFinderRemote (Private)
- (void)setConnected:(BOOL)flag;
@end

@implementation NTPathFinderRemote

- (id)initWithDelegate:(id<NTPathFinderRemoteDelegateProtocol>)delegate;
{
	self = [super init];
	
	_delegate = delegate;  // no retain
	
	_connection = [[NTPathFinderConnection alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(connectedToBackgroundApplication:)
                                                 name:kNTNowConnectedtoBackgroundApplication
                                               object:_connection]; 
	
	
	return self;
}

- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_connection release];
	[super dealloc];
}

//---------------------------------------------------------- 
//  connected 
//---------------------------------------------------------- 
- (BOOL)connected
{
    return mConnected;
}

- (void)activate; // brings app to front
{
	if ([self connected])
		[_connection activate];
}

// must make connection before doing anything else
- (void)connect;
{
	if (![self connected])
		[_connection connect];
}

	// ** information
- (NSArray*)selection;
{
	if ([self connected])
		return [_connection selection];
	
	return nil;
}

- (NSArray*)volumes;
{
	if ([self connected])
		return [_connection volumes];
	
	return nil;
}

- (NSArray*)directoryListing:(NSString*)path visibleItemsOnly:(BOOL)visibleItemsOnly;
{
	if ([self connected])
		return [_connection directoryListing:path visibleItemsOnly:visibleItemsOnly];
	
	return nil;
}

	// front most window's current displayed directory
- (NSString*)currentDirectory;  
{
	if ([self connected])
		return [_connection currentDirectory];
	
	return nil;
}

// ============================================================================
// ============================================================================
// ** commands

- (void)revealPaths:(NSArray*)paths behavior:(NTRevealPathBehavior)behavior;
{
	if ([self connected])
		[_connection revealPaths:paths behavior:behavior];
}

- (void)selectPaths:(NSArray*)paths byExtendingSelection:(BOOL)extend;
{
	if ([self connected])
		[_connection selectPaths:paths byExtendingSelection:extend];
}

- (void)showGetInfo:(NSString*)path;
{
	if ([self connected])
		[_connection showGetInfo:path];
}

- (void)ejectVolume:(NSString*)path;
{
	if ([self connected])
		[_connection ejectVolume:path];
}

- (void)moveToTrash:(NSString*)path;
{
	if ([self connected])
		[_connection moveToTrash:path];
}
	// destination can include desired filename or just destination folder, or nil in the case of copy and makeAlias
- (void)copy:(NSString*)path destination:(NSString*)destination;
{
	if ([self connected])
		[_connection copy:path destination:destination];
}

- (void)move:(NSString*)path destination:(NSString*)destination;
{
	if ([self connected])
		[_connection move:path destination:destination];
}

- (void)makeAlias:(NSString*)path destination:(NSString*)destination;
{
	if ([self connected])
		[_connection makeAlias:path destination:destination];
}

- (void)rename:(NSString*)path newName:(NSString*)newName;
{
	if ([self connected])
		[_connection rename:path newName:newName];
}

- (void)duplicate:(NSString*)path;
{
	if ([self connected])
		[_connection duplicate:path];
}

@end

@implementation NTPathFinderRemote (Private)

- (void)setConnected:(BOOL)flag
{
    mConnected = flag;
}

- (void)connectedToBackgroundApplication:(NSNotification*)notification;
{
	[self setConnected:YES];
	
	[_delegate PFR_connectionStatus:kPFR_Connected];
}

@end


