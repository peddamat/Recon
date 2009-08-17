//
//  NTSampleMenuPluginWindowController.m
//  Path Finder
//
//  Created by Steve Gehrman on Fri Mar 07 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import "NTSampleMenuPluginWindowController.h"
#import "NTMenuPluginProtocol.h"

@interface NTSampleMenuPluginWindowController (Private)
- (id)objectController;
- (void)setObjectController:(id)theObjectController;

- (void)processDescs:(NSArray*)descs;

- (NSMutableDictionary *)model;
- (void)setModel:(NSMutableDictionary *)theModel;

- (id<NTPathFinderPluginHostProtocol>)host;
- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost;
@end

@implementation NTSampleMenuPluginWindowController

+ (id)window:(id<NTPathFinderPluginHostProtocol>)host;
{
    // releases itself when the window is closed
    NTSampleMenuPluginWindowController *result = [[NTSampleMenuPluginWindowController alloc] initWithWindowNibName:@"SampleMenuPlugin"];

    [result setHost:host];
    [result showWindow:nil];
    
    return result;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[self setObjectController:nil];
    [self setHost:nil];
	[self setModel:nil];

    [super dealloc];
}

// NSWindowController override
- (void)windowWillLoad;
{
    [super windowWillLoad];

    [self setWindowFrameAutosaveName:@"SampleMenuPlugin autosave name"];
    [self setShouldCascadeWindows:YES];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self setObjectController:nil]; 
    [self autorelease];
}    

@end

@implementation NTSampleMenuPluginWindowController (Actions)

- (IBAction)getInfoAction:(id)sender;
{
    NSArray* selection = [[self host] selection:nil browserID:nil];

    if ([selection count])
        [[self host] showGetInfoWindows:selection];
    else
        [[self host] showGetInfoWindows:[NSArray arrayWithObject:NSHomeDirectory()]];
}

- (IBAction)newTextDocumentAction:(id)sender;
{
	NSString* output = [[[self host] selection:nil browserID:nil] description];
	
	if (![output length])
		output = @"no selection";
	
    [[self host] textDocumentWithString:output];
}

- (IBAction)showHomeDirectoryAction:(id)sender;
{
    [[self host] revealItem:[[self host] newFSItem:NSHomeDirectory()] window:nil browserID:nil];
}

- (IBAction)getSelectionAction:(id)sender;
{
    // process the selected files
    [self processDescs:nil];
}

- (IBAction)homePageAction:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.cocoatech.com/wiki-dev/"]];
}

@end

@implementation NTSampleMenuPluginWindowController (Private)

//---------------------------------------------------------- 
//  model 
//---------------------------------------------------------- 
- (NSMutableDictionary *)model
{
	if (!mModel)
		[self setModel:[NSMutableDictionary dictionary]];
	
    return mModel; 
}

- (void)setModel:(NSMutableDictionary *)theModel
{
    if (mModel != theModel)
    {
        [mModel release];
        mModel = [theModel retain];
    }
}

//---------------------------------------------------------- 
//  host 
//---------------------------------------------------------- 
- (id<NTPathFinderPluginHostProtocol>)host
{
    return mHost; 
}

- (void)setHost:(id<NTPathFinderPluginHostProtocol>)theHost
{
    if (mHost != theHost)
    {
        [mHost release];
        mHost = [theHost retain];
    }
}

//---------------------------------------------------------- 
//  objectController 
//---------------------------------------------------------- 
- (id)objectController
{
    return mObjectController; 
}

- (void)setObjectController:(id)theObjectController
{
    if (mObjectController != theObjectController)
    {
        [mObjectController release];
        mObjectController = [theObjectController retain];
    }
}

- (void)processDescs:(NSArray*)descs;
{
	if (!descs)
		descs = [[self host] selection:nil browserID:nil];
	
    NSEnumerator* enumerator = [descs objectEnumerator];
    NSString *path;
    id<NTFSItem> desc;
	NSMutableString* output = [NSMutableString string];
	
    while (desc = [enumerator nextObject])
    {
		path = [desc path];
		
		if (path)
		{
			[output appendString:path];
			[output appendString:@"\r"];
		}
	}
		
	NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:output attributes:nil] autorelease];
    [attrString addAttribute:NSFontAttributeName value:[NSFont userFontOfSize:10] range:NSMakeRange(0, [attrString length])];
	
	[[self model] setObject:attrString forKey:@"output"];
}

@end

