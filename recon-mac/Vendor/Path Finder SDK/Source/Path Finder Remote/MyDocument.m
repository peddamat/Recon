//
//  MyDocument.m
//  Path Finder Remote
//
//  Created by Steve Gehrman on 8/29/04.
//  Copyright __MyCompanyName__ 2004 . All rights reserved.
//

#import "MyDocument.h"

enum
{
	kGetInfo,
	kDirectoryListing,
	kEject,
	kMoveToTrash,
	kDuplicate,
	kMakeAlias,
	kRename,
	kShowPath
};

@interface MyDocument (Private)
- (id)outputTextView;
- (void)setOutputTextView:(id)theOutputTextView;

- (NSTextField *)pathText;
- (void)setPathText:(NSTextField *)thePathText;

- (NSTextField *)pathText2;
- (void)setPathText2:(NSTextField *)thePathText2;

- (NSPopUpButton *)commandPopUp;
- (void)setCommandPopUp:(NSPopUpButton *)theCommandPopUp;

- (NSFont *)font;
- (void)setFont:(NSFont *)theFont;

- (NTPathFinderRemote *)pathFinderRemote;
- (void)setPathFinderRemote:(NTPathFinderRemote *)thePathFinderRemote;

- (void)displayText:(NSString*)text;
- (NSString*)getPath;
- (NSString*)getPath2;
@end

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
    
		[self setPathFinderRemote:[[[NTPathFinderRemote alloc] initWithDelegate:self] autorelease]];
		
		[[self pathFinderRemote] connect];

		[self setFont:[NSFont systemFontOfSize:12]];
			
    }
    return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setOutputTextView:nil];
    [self setPathText:nil];
    [self setPathText2:nil];
    [self setCommandPopUp:nil];
    [self setFont:nil];
    [self setPathFinderRemote:nil];
    [super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

	[self displayText:[NSString stringWithFormat:@"RevealInPathFinderEnabled preference is set: %@", revealInPathFinderPreferenceEnabled() ? @"YES" : @"NO"]];
	
	CFStringRef localizedMenuItem = revealInPathFinderLocalizedString();
	[self displayText:[NSString stringWithFormat:@"revealInPathFinderLocalizedString: %@", localizedMenuItem]];
	CFRelease(localizedMenuItem);
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    // Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    return YES;
}

- (void)PFR_connectionStatus:(NTPathFinderConnectionStatus)status;  // called after a call to connect or called if connection is dropped
{
	if (status == kPFR_Connected)
		NSLog(@"Connected");
	else
		NSLog(@"Failed to Connect");
}

@end

@implementation MyDocument (Private)

- (void)displayText:(NSString*)text
{
	text = [text stringByAppendingString:@"\n"];
	
    NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:text] autorelease];
	
    [attrString addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [attrString length])];
	
    [[[self outputTextView] textStorage] appendAttributedString:attrString];
}

- (NSString*)getPath;
{
	return [[self pathText] stringValue];
}

- (NSString*)getPath2;
{
	return [[self pathText2] stringValue];
}

//---------------------------------------------------------- 
//  outputTextView 
//---------------------------------------------------------- 
- (id)outputTextView
{
    return mOutputTextView; 
}

- (void)setOutputTextView:(id)theOutputTextView
{
    if (mOutputTextView != theOutputTextView)
    {
        [mOutputTextView release];
        mOutputTextView = [theOutputTextView retain];
    }
}

//---------------------------------------------------------- 
//  pathText 
//---------------------------------------------------------- 
- (NSTextField *)pathText
{
    return mPathText; 
}

- (void)setPathText:(NSTextField *)thePathText
{
    if (mPathText != thePathText)
    {
        [mPathText release];
        mPathText = [thePathText retain];
    }
}

//---------------------------------------------------------- 
//  pathText2 
//---------------------------------------------------------- 
- (NSTextField *)pathText2
{
    return mPathText2; 
}

- (void)setPathText2:(NSTextField *)thePathText2
{
    if (mPathText2 != thePathText2)
    {
        [mPathText2 release];
        mPathText2 = [thePathText2 retain];
    }
}

//---------------------------------------------------------- 
//  commandPopUp 
//---------------------------------------------------------- 
- (NSPopUpButton *)commandPopUp
{
    return mCommandPopUp; 
}

- (void)setCommandPopUp:(NSPopUpButton *)theCommandPopUp
{
    if (mCommandPopUp != theCommandPopUp)
    {
        [mCommandPopUp release];
        mCommandPopUp = [theCommandPopUp retain];
    }
}

//---------------------------------------------------------- 
//  font 
//---------------------------------------------------------- 
- (NSFont *)font
{
    return mFont; 
}

- (void)setFont:(NSFont *)theFont
{
    if (mFont != theFont)
    {
        [mFont release];
        mFont = [theFont retain];
    }
}

//---------------------------------------------------------- 
//  pathFinderRemote 
//---------------------------------------------------------- 
- (NTPathFinderRemote *)pathFinderRemote
{
    return mPathFinderRemote; 
}

- (void)setPathFinderRemote:(NTPathFinderRemote *)thePathFinderRemote
{
    if (mPathFinderRemote != thePathFinderRemote)
    {
        [mPathFinderRemote release];
        mPathFinderRemote = [thePathFinderRemote retain];
    }
}

@end

@implementation MyDocument (Actions)

- (IBAction)commandPopupAction:(id)sender;
{
	// do nothing
}

- (IBAction)currentDirectoryButtonAction:(id)sender;
{
	NSString* directory = [[self pathFinderRemote] currentDirectory];
	
	if (directory)
		[self displayText:directory];					
}

- (IBAction)doItButtonAction:(id)sender;
{
	NSString* path = [self getPath];
	NSString* path2 = [self getPath2];
	
	if (![path2 length])
		path2 = nil;
	
	if (path)
	{		
		switch ([[[self commandPopUp] selectedItem] tag])
		{
			case kGetInfo:
				[[self pathFinderRemote] showGetInfo:path];
				[[self pathFinderRemote] activate];
				break;
			case kDirectoryListing:
			{
				NSArray *listing = [[self pathFinderRemote] directoryListing:path visibleItemsOnly:NO];
				NSString* path;
				
				for (path in listing)
					[self displayText:path];					
			}
				break;
			case kEject:
				[[self pathFinderRemote] ejectVolume:path];
				break;
			case kMoveToTrash:
				[[self pathFinderRemote] moveToTrash:path];
				break;
			case kDuplicate:
				[[self pathFinderRemote] duplicate:path];
				break;
			case kMakeAlias:
				[[self pathFinderRemote] makeAlias:path destination:nil];
				break;
			case kRename:
				break;
			case kShowPath:
			{
				NSArray* paths;
				
				if (path2)
					paths = [NSArray arrayWithObjects:path, path2, nil];
				else
					paths = [NSArray arrayWithObject:path];
				
				[[self pathFinderRemote] revealPaths:paths behavior:kDefaultRevealBehavior];
				[[self pathFinderRemote] activate];
			}
				break;
		}
	}
}

- (IBAction)selectionButtonAction:(id)sender;
{
	NSArray *listing = [[self pathFinderRemote] selection];
	NSString* path;
	
	for (path in listing)
		[self displayText:path];					
}

- (IBAction)volumesButtonAction:(id)sender;
{
	NSArray *listing = [[self pathFinderRemote] volumes];
	NSString* path;
	
	for (path in listing)
		[self displayText:path];						
}

@end


