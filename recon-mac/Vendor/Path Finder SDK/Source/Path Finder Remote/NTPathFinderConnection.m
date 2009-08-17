//
//  NTPathFinderConnection.m
//  Path Finder Remote
//
//  Created by Steve Gehrman on 8/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NTPathFinderConnection.h"
#import "NTPathFinderProtocol.h"

// this handles communicating with our background application

@interface NTPathFinderConnection (Private)
- (BOOL)makeConnectionToBackgroundApp;
- (void)launchBackgroundApp;
@end

@implementation NTPathFinderConnection

- (id)init;
{
    self = [super init];
        
    return self;
}

- (void)dealloc;
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:kBackgroundAppLaunchedNotificationName object:nil];
    [_distantObject release];
    [_connection release];
	
    [super dealloc];
}

- (void)connect;
{
	// make a connection to our background app, if background app not running, start it now
	if (![self makeConnectionToBackgroundApp])
		[self launchBackgroundApp];
}

- (void)activate; // brings app to front
{
	[_distantObject activate];
}

// ** information
- (NSArray*)selection;
{
    return [_distantObject selection];
}

- (NSArray*)volumes;
{
    return [_distantObject volumes];
}

- (NSArray*)directoryListing:(NSString*)path visibleItemsOnly:(BOOL)visibleItemsOnly;
{
    return [_distantObject directoryListing:path visibleItemsOnly:visibleItemsOnly];
}

// front most window's current displayed directory
- (NSString*)currentDirectory;  
{
    return [_distantObject currentDirectory];
}

// ** commands
- (void)revealPaths:(NSArray *)paths behavior:(NTRevealPathBehavior)behavior;
{
	[_distantObject revealPaths:paths behavior:behavior];
}

- (void)selectPaths:(NSArray *)paths byExtendingSelection:(BOOL)extend;
{
	[_distantObject selectPaths:paths byExtendingSelection:extend];
}

- (void)showGetInfo:(NSString*)path;
{
	[_distantObject showGetInfo:path];
}

- (void)ejectVolume:(NSString*)path;
{
	[_distantObject ejectVolume:path];
}

- (void)moveToTrash:(NSString*)path;
{
	[_distantObject moveToTrash:path];
}

// destination can include desired filename or just destination folder, or nil in the case of copy and makeAlias
- (void)copy:(NSString*)path destination:(NSString*)destination;
{
	[_distantObject copy:path destination:destination];
}

- (void)move:(NSString*)path destination:(NSString*)destination;
{
	[_distantObject move:path destination:destination];
}

- (void)makeAlias:(NSString*)path destination:(NSString*)destination;
{
	[_distantObject makeAlias:path destination:destination];
}

- (void)rename:(NSString*)path newName:(NSString*)newName;
{
	[_distantObject rename:path newName:newName];
}

- (void)duplicate:(NSString*)path;
{
	[_distantObject duplicate:path];
}

@end

@implementation NTPathFinderConnection (Private)

- (void)launchBackgroundApp;
{
	NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:kBackgroundAppName];
	
	if (path)
	{
		// set up so we get notified when the app finishes launching
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundAppLaunchedNotification:) name:kBackgroundAppLaunchedNotificationName object:nil];
		
		// launch the background app
		[[NSWorkspace sharedWorkspace] launchApplication:path];
	}
}

- (BOOL)makeConnectionToBackgroundApp;
{
    if (!_connection)
    {
        _connection = [[NSConnection connectionWithRegisteredName:kPathFinderListenerName host:nil] retain];
        if (_connection)
        {
            _distantObject = [[_connection rootProxy] retain];
            
            if ([_distantObject conformsToProtocol:@protocol(NTPathFinderProtocol)])
            {
                [_distantObject setProtocolForProxy:@protocol(NTPathFinderProtocol)];
                
                // post notification in a delay so users can successfully set up the notification first
                [self performSelector:@selector(postNotification:) withObject:nil afterDelay:0];
            }
            else
                [[NSException exceptionWithName:@"distantObject" reason:@"Does not conform to protocol NTPathFinderProtocol" userInfo:nil] raise];
        }
    }
    
    return (_connection != nil);
}    

- (void)backgroundAppLaunchedNotification:(NSNotification*)notification;
{
    [self makeConnectionToBackgroundApp];
}

- (void)postNotification:(id)unused;
{
    // local notification saying that we are now connected to the background application
    [[NSNotificationCenter defaultCenter] postNotificationName:kNTNowConnectedtoBackgroundApplication object:self];
}

@end
