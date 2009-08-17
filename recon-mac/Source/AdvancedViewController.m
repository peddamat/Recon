//
//  AdvancedViewController.m
//  recon
//
//  Created by Sumanth Peddamatham on 8/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AdvancedViewController.h"

#import "Host.h"
#import "Port.h"
#import "Profile.h"
#import "Session.h"
#import "OsMatch.h"
#import "HostNote.h"

#import "SessionManager.h"
#import "PathTransformer.h"
#import "StringToAttribStringTransformer.h"

#import "MyTerminalView.h"
#import "ColorGradientView.h"

@class NotesTableView;

@implementation AdvancedViewController

@synthesize targetBarAdvancedContent;
@synthesize consoleOutputView;

- (id)init 
{
   if (self = [super init])
   {
      if (![super initWithNibName:@"Advanced"
                           bundle:nil]) {
         return nil;
      }
      [self setTitle:@"Advanced"];      
   }   
   
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self
          selector:@selector(receivedStringFromConsole:)
              name:@"BAFstringFromConsole"
            object:nil];

   [nc addObserver:self
          selector:@selector(receivedStringFromConsoleAlternate:)
              name:@"BAFstringFromConsoleAlternate"
            object:nil];

   [nc addObserver:self
          selector:@selector(mainWindowZoom:)
              name:@"BAFmainWindowZoom"
            object:nil];   

   [nc addObserver:self
          selector:@selector(mainWindowUnzoom:)
              name:@"BAFmainWindowUnzoom"
            object:nil];   
   
   [nc addObserver:self
          selector:@selector(toggleNotesInternalView)
              name:@"BAFtoggleNotes"
            object:nil];   
   
   [nc addObserver:self
          selector:@selector(toggleSessionsInternalView)
              name:@"BAFtoggleSessions"
            object:nil];      

   // Listen for notifications from notes editor
   [nc addObserver:self
          selector:@selector(controlTextDidEndEditing:)
              name:@"NSControlTextDidEndEditingNotification"
            object:nil];      
   
   [portsInHostView retain];
   [scriptOutputView retain];
   [consoleOutputView retain];
      
   return self;
}

// TODO: This ain't working!
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
   if ([[aNotification object] isKindOfClass:[notesTableView class]])
   {
      [notesTextView setSelectedRange:NSMakeRange(0, [[notesTextView textStorage] length])];   
   }
}

// -------------------------------------------------------------------------------
//	windowControllerDidLoadNib: This is where we perform most of the initial app
//                             setup.
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
   // Set-up Ports in Host and Scripts Output view
   [portsInHostView setFrame:[outputPlaceholder bounds]];
   [outputPlaceholder addSubview:portsInHostView];
   
   // ... and the Host TableView
   [hostsTableView setTarget:self];
   [hostsTableView setDoubleAction:@selector(hostsTableDoubleClick)];
   
   // ... and the Services TableView
   [portsTableView setTarget:self];
   [portsTableView setDoubleAction:@selector(portsTableDoubleClick)];   
   
   // ... and the Oses TableView
   [osesTableView setTarget:self];
   [osesTableView setDoubleAction:@selector(osesTableDoubleClick)];   
   
   // ... and the Ports TableView in the Results Tab
   [resultsPortsTableView setTarget:self];
   [resultsPortsTableView setDoubleAction:@selector(resultsPortsTableDoubleClick)];   
   
   [targetBarAdvancedContent retain];   
   [sideBarAdvancedContent retain];
   [workspaceAdvancedContent retain];      
   
   [self createHostsMenu];   
   [self createPortsInHostMenu];
   [self createPortsInSessionMenu];
      
   // Register value transformers
   id transformer = [[[PathTransformer alloc] init] autorelease];   
   [NSValueTransformer setValueTransformer:transformer forName:@"PathTransformer"];   

   transformer = [[[StringToAttribStringTransformer alloc] init] autorelease];   
   [NSValueTransformer setValueTransformer:transformer forName:@"StringToAttribStringTransformer"];   
   
   // Spiffy-fy labels
   [notesLabel setFrameCenterRotation:90];
   [[notesLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];    

   [[ipTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];   
   [[sessionsLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];      
   [[hostStatusTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];     
   
   // Draw gradient manually, since BWGradient doesn't support angles yet
   [notesGradientView setStartingColor:
    [NSColor colorWithDeviceRed:202.0/255.0 green:202.0/255.0 blue:202.0/255.0 alpha:1.0]];           
   [notesGradientView setEndingColor:
    [NSColor colorWithDeviceRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:1.0]];
   [notesGradientView setAngle:180];   

   // TODO: THIS IS HACKY.  BWSplitView doesn't provide a way to initialize
   //       a subview collapsed. Setting the divider position manually doesn't
   //       seem to work either.  :(
   if ([[NSApp mainWindow] isZoomed] == NO)
   {
      [self closeNotesInternalView];
      [self closeSessionsInternalView];   
   }
   
   //   NSString *urlText = [NSString stringWithString:@"http://127.0.0.1:55555/"];      
   //   [[webby mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];        
}   

#pragma mark -
#pragma mark Beautifiers

- (IBAction)focusInputField:(id)sender {
	[sessionTarget selectText:self];
   //	[[sessionTarget currentEditor] setSelectedRange:NSMakeRange([[sessionTarget stringValue] length], 0)];	
}

#pragma mark -
#pragma mark View switch handlers

- (IBAction)modeSwitch:(id)sender
{
   switch ([sender selectedSegment]) {
      case 0:
         [self switchToPortsInHost:nil];
         break;
      case 1:
         [self switchToScriptOutput:nil];
         break;
      case 2:
         [self switchToConsole:nil];
         break;
      case 3:
         [self switchToHostsInSession:nil];
         break;         
      default:
         break;
   }
}

- (IBAction)switchToPortsInHost:(id)sender
{
   [advancedModeSwitchBar setSelectedSegment:0];
   
   [portsInHostView setFrame:[outputPlaceholder bounds]];
   [[outputPlaceholder animator] replaceSubview:[[outputPlaceholder subviews] lastObject] 
                                           with:portsInHostView];         
}

- (IBAction)switchToScriptOutput:(id)sender
{
   [advancedModeSwitchBar setSelectedSegment:1];
   
   [scriptOutputView setFrame:[outputPlaceholder bounds]];
   [[outputPlaceholder animator] replaceSubview:[[outputPlaceholder subviews] lastObject] 
                                           with:scriptOutputView];         
}

- (IBAction)switchToConsole:(id)sender
{
   [advancedModeSwitchBar setSelectedSegment:2];
   
   [consoleOutputView setFrame:[outputPlaceholder bounds]];
   [[outputPlaceholder animator] replaceSubview:[[outputPlaceholder subviews] lastObject] 
                                           with:consoleOutputView];         
   [consoleOutputView refreshWindow];
//   [consoleOutputView lockFocus];
//   [consoleOutputView setFrame:[outputPlaceholderOffScreen bounds]];
//   [outputPlaceholder replaceSubview:[[outputPlaceholder subviews] lastObject] 
//                                           with:consoleOutputView];         
//
//   [consoleOutputView setFrame:[outputPlaceholderOffScreen frame]];
//   [[consoleOutputView animator] setFrame:[outputPlaceholder bounds]];
   
}

- (IBAction)switchToHostsInSession:(id)sender
{
   [advancedModeSwitchBar setSelectedSegment:3];
   
   [hostsInSessionView setFrame:[outputPlaceholder bounds]];
   [[outputPlaceholder animator] replaceSubview:[[outputPlaceholder subviews] lastObject] 
                                           with:hostsInSessionView];         
}

#pragma mark -
#pragma mark Interface twiddling handlers
// -------------------------------------------------------------------------------
//	segControlClicked: Delete/Play/Add segmented control in the lower-right
// -------------------------------------------------------------------------------
- (IBAction)segControlClicked:(id)sender
{
   switch ([sender selectedSegment]) {
      case 0:
         [sidebarSplitView toggleCollapse:testy];
         break;
      case 1:
         [NSApp sendAction:@selector(toggleSessions:) to:nil from:self];
         break;
      case 2:
         [NSApp sendAction:@selector(toggleNotes:) to:nil from:self];
         break;         
      default:
         break;
   }
}

#pragma mark -
#pragma mark Table click handlers

// -------------------------------------------------------------------------------
//	createHostsMenu: Create a right-click menu for the hosts Table View.
// -------------------------------------------------------------------------------
- (void)createHostsMenu
{
   NSArray *array = [managedObjectContext fetchObjectsForEntityName:@"Profile" withPredicate:
                     @"(parent.name LIKE[c] 'Defaults') OR (parent.name LIKE[c] 'User Profiles')"];   
   
   NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                       initWithKey:@"name" ascending:YES];
   
   NSMutableArray *sa = [NSMutableArray arrayWithArray:array];
   [sa sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];    
   [sortDescriptor release];
   
   NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"Queue with"
                                               action:@selector(handleHostsMenuClick:)
                                        keyEquivalent:@""];   
   NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"Profile"];
   [mi setSubmenu:submenu];
   
   for (id obj in sa)
   {
      NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[obj name]
                                                  action:@selector(handleHostsMenuClick:)
                                           keyEquivalent:@""];
      [mi setTag:10];
      [submenu addItem:mi];
      [mi release];      
      
   }
   [hostsContextMenu addItem:mi];
}

// -------------------------------------------------------------------------------
//	createPortsInHostsMenu: Create a right-click menu for the ports in host Table View.
// -------------------------------------------------------------------------------
- (void)createPortsInHostMenu
{   
   NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"Connect with"
                                               action:@selector(handlePortsInHostMenuClick:)
                                        keyEquivalent:@""];   
   NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"Utility"];
   [mi setSubmenu:submenu];

   // NCat
   NSMenuItem *smi = [[NSMenuItem alloc] initWithTitle:@"Ncat"
                                               action:@selector(handlePortsInHostMenuClick:)
                                        keyEquivalent:@""];
   [smi setTag:10];
   [submenu addItem:smi];
   [smi release];      
      
   [portsInHostContextMenu addItem:mi];
}

// -------------------------------------------------------------------------------
//	createPortsInHostsMenu: Create a right-click menu for the ports in session Table View.
// -------------------------------------------------------------------------------
- (void)createPortsInSessionMenu
{   
   NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"Connect with"
                                               action:@selector(handlePortsInSessionMenuClick:)
                                        keyEquivalent:@""];   
   NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"Utility"];
   [mi setSubmenu:submenu];
   
   // NCat
   NSMenuItem *smi = [[NSMenuItem alloc] initWithTitle:@"Ncat"
                                                action:@selector(handlePortsInSessionMenuClick:)
                                         keyEquivalent:@""];
   [smi setTag:10];
   [submenu addItem:smi];
   [smi release];      
   
   [portsInSessionContextMenu addItem:mi];
}

// -------------------------------------------------------------------------------
//	handleHostsMenuClick: 
// -------------------------------------------------------------------------------
- (IBAction)handleHostsMenuClick:(id)sender
{
   //ANSLog(@"MyDocument: handleHostsMenuClick: %@", [sender title]);
   
   // If we want to queue selected hosts... (10 is a magic number specified in IB)
   if ([sender tag] == 10)
   {
      // Grab the desired profile...
      NSArray *s = [managedObjectContext fetchObjectsForEntityName:@"Profile" withPredicate:
                    @"(name LIKE[c] %@)", [sender title]]; 
      Profile *p = [s lastObject];
      
      // Grab the selected hosts from the hostsController
      NSArray *selectedHosts = [hostsInSessionController selectedObjects];
      
      NSString *hostsIpCSV = [[NSString alloc] init];
      
      // Create a comma-seperated string of target ip's
      if ([selectedHosts count] > 1)
      {
         Host *lastHost = [selectedHosts lastObject];
         
         for (Host *host in selectedHosts)
         {
            if (host == lastHost)
               break;
            hostsIpCSV = [hostsIpCSV stringByAppendingFormat:@"%@ ", [host ipv4Address]];
         }
      }
      
      hostsIpCSV = [hostsIpCSV stringByAppendingString:[[selectedHosts lastObject] ipv4Address]];
      
      //      // Create a Target string based on the hosts ip's
      //      NSString *ip = [[a lastObject] ipv4Address];
      
      // BEAUTIFIER: When queueing up a new host, keep the selection on the current Session
      Session *currentSession = [[sessionsArrayController selectedObjects] lastObject];      
      
      // Grab the Session Manager object
      SessionManager *sessionManager = [SessionManager sharedSessionManager];
      
      [sessionManager queueSessionWithProfile:p withTarget:hostsIpCSV];
      
      // BEAUTIFIER
      [sessionsArrayController setSelectedObjects:[NSArray arrayWithObject:currentSession]];
   }
}

// -------------------------------------------------------------------------------
//	handlePortsInHostMenuClick: 
// -------------------------------------------------------------------------------
- (IBAction)handlePortsInHostMenuClick:(id)sender
{
   //ANSLog(@"MyDocument: handleHostsMenuClick: %@", [sender title]);
   
   NSString *command = [sender title];
   
   // If we want to queue selected hosts... (10 is a magic number specified in IB)
   if ([sender tag] == 10)
   {
      if ([command isEqualToString:@"Ncat"] == YES)
      {
         Port *selectedPort = [[portsInHostController selectedObjects] lastObject];
         NSString *c = [NSString stringWithFormat:@"ncat %@ %@", selectedPort.host.ipv4Address, selectedPort.number];
         
         [self runCommandInNewConsoleTab:c];
         [self switchToConsole:nil];
      }
   }
}

// -------------------------------------------------------------------------------
//	handlePortsInSessionMenuClick: 
// -------------------------------------------------------------------------------
- (IBAction)handlePortsInSessionMenuClick:(id)sender
{
   //ANSLog(@"MyDocument: handleHostsMenuClick: %@", [sender title]);
   
   NSString *command = [sender title];
   
   // If we want to queue selected hosts... (10 is a magic number specified in IB)
   if ([sender tag] == 10)
   {
      if ([command isEqualToString:@"Ncat"] == YES)
      {
         Port *selectedPort = [[portsInSessionController selectedObjects] lastObject];
         NSString *c = [NSString stringWithFormat:@"ncat %@ %@", selectedPort.host.ipv4Address, selectedPort.number];
         
         [self runCommandInNewConsoleTab:c];
         [self switchToConsole:nil];
      }
   }
}

#pragma mark -
#pragma mark Table double-click handlers

// -------------------------------------------------------------------------------
//	Table click handlers
// -------------------------------------------------------------------------------
- (void)hostsTableDoubleClick
{
   // If we're in console mode, send the IP address to the current console
   if ([advancedModeSwitchBar selectedSegment] == 2)
   {
      Host *selectedHost = [[hostsInSessionController selectedObjects] lastObject];      
      NSString *hostIP = [NSString stringWithFormat:@"%@ ", [selectedHost ipv4Address]];
      
      [consoleOutputView sendStringToCurrentTab:hostIP];
   }
}

- (void)portsTableDoubleClick 
{
   // Get selected port
   Port *selectedPort = [[portsInSessionController selectedObjects] lastObject];
   // Get host for selected port
   Host *selectedHost = selectedPort.host;
   
   [hostsInSessionController setSelectedObjects:[NSArray arrayWithObject:selectedHost]];
   // If user double-clicks on a Host menu item, switch to results view
//   [self toggleResults:self];
}

- (void)osesTableDoubleClick
{
   // Get selected port
   OsMatch *selectedOs = [[osesInSessionController selectedObjects] lastObject];
   // Get host for selected port
   Host *selectedHost = selectedOs.host;
   
   [hostsInSessionController setSelectedObjects:[NSArray arrayWithObject:selectedHost]];
   // If user double-clicks on a Host menu item, switch to results view
//   [self toggleResults:self];
}

- (void)resultsPortsTableDoubleClick
{
   // Find clicked row from sessionsTableView
   NSInteger selectedRow = [resultsPortsTableView selectedRow];
   // Get selected object from sessionsArrayController 
   Port *selectedPort = [[portsInHostController arrangedObjects] objectAtIndex:selectedRow];
   Host *selectedHost = [selectedPort host];
   
   NSString *url;
   switch ([[selectedPort number] integerValue]) {
      case 80:
         url = [NSString stringWithFormat:@"http://%@", [selectedHost ipv4Address]];
         [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
         break;
         
      case 139:
      case 445:
         url = [NSString stringWithFormat:@"smb://%@", [selectedHost ipv4Address]];
         [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
         break;         
      default:
         break;
   }
   
   // TODO: Parse the port name for services running on non-standard ports
}

#pragma mark -
#pragma mark Menu validators

// -------------------------------------------------------------------------------
//	Menu click handlers
// -------------------------------------------------------------------------------

// Enable/Disable menu depending on context
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
//   NSLog(@"Validate");
   
   BOOL enabled = NO;
   
   if ([menuItem action] == @selector(handleHostsMenuClick:))
   {
      if ([[hostsInSessionController selectedObjects] count] == 0)
      if ([hostsTableView clickedRow] == -1)
         enabled = NO;
      else
         enabled = YES;
   }
   else
   {
//      enabled = [super validateMenuItem:menuItem];
   }
  
//   return enabled;
   return YES;
}


// Handle context menu clicks in Sessions TableView
- (void)menuNeedsUpdate:(NSMenu *)menu 
{
//   NSInteger clickedRow = [sessionsTableView clickedRow];
//   NSInteger selectedRow = [sessionsTableView selectedRow];
//   NSInteger numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   //(NSIndexSet *)selectedRowIndexes = [sessionsTableView selectedRowIndexes];
   
   // If clickedRow == -1, the user hasn't clicked on a session
   
   if (menu == hostsContextMenu) 
   {
//      Session *s = [self clickedSessionInDrawer];
//      if ([s status] == @"
   }
   else if (menu == portsInHostContextMenu)
   {
   }
   else
   {
//   [sessionsContextMenu update];
   }
}

#pragma mark -
#pragma mark Console interaction handlers

// -------------------------------------------------------------------------------
//	runCommandInNewConsoleTab: Create a new console tab and execute a command in it
// -------------------------------------------------------------------------------
- (void)runCommandInNewConsoleTab:(NSString *)command
{
   [consoleOutputView addNewTabWithCommand:command];
}

// -------------------------------------------------------------------------------
//	addStringToCurrentConsoleTab: Add a string to the current console tab
// -------------------------------------------------------------------------------
- (void)addStringToCurrentConsoleTab:(NSString *)string
{
   [consoleOutputView sendStringToCurrentTab:string];   
}

// -------------------------------------------------------------------------------
//	receivedStringFromConsole: If the user CMD-clicks a highlighted string in the
//                            console...
// -------------------------------------------------------------------------------
- (void)receivedStringFromConsole:(NSNotification *)notification
{   
   NSString *selectedText = [notification object];
   selectedText = [selectedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
   selectedText = [selectedText stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];         
   
   // Only grab the first line of the selected text
//   NSArray *line = [selectedText componentsSeparatedByString:@"\n"];
   
   // Prepend the string to the target combo box
   
   NSString *currentString = [sessionTarget stringValue];
   currentString = [currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
   currentString = [currentString stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];      
   
   if ([currentString isEqualToString:@""])
      currentString = [NSString stringWithFormat:@"%@", selectedText];
   else
      currentString = [NSString stringWithFormat:@"%@, %@", selectedText, currentString];
   [sessionTarget setStringValue:currentString];
}

// -------------------------------------------------------------------------------
//	receivedStringFromConsoleAlternate: If the user ALT-CMD-clicks a highlighted string
//                            in the console...
// -------------------------------------------------------------------------------
- (void)receivedStringFromConsoleAlternate:(NSNotification *)notification
{
   NSLog(@"AdvancedViewController: receivedStringFromConsoleAlternate: %@", [notification object]);
   
   NSString *selectedText = [notification object];
   selectedText = [selectedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
   selectedText = [selectedText stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];            
   
   // Only grab the first line of the selected text
//   NSArray *line = [selectedText componentsSeparatedByString:@"\n"];
   
   // Set the session target equal to the selected text
   
   [sessionTarget setStringValue:selectedText];   
}

#pragma mark -
#pragma mark Notes methods

- (IBAction)addNote:(id)sender
{
   //   [NSApp sendAction:@selector(addNote:) to:nil from:self];
   HostNote *h = [notesInHostController newObject];
   
   if (h == nil) {
      NSBeep();
      return;
   }
   
   h.date = [NSDate date];
   h.name = @"New Note";
   [notesInHostController addObject:h];
   [h release];
   
   // Re-sort (in case the user has sorted a column)
   [notesInHostController rearrangeObjects];
   
   // Get the sorted array
   NSArray *a = [notesInHostController arrangedObjects];
   
   // Find the object just added
   int row = [a indexOfObjectIdenticalTo:h];
   //   NSLog(@"starting edit of %@ in row %d", h, row);
   
   // Begin the edit in the first column
   [notesTableView editColumn:0
                          row:row
                    withEvent:nil
                       select:YES];   
}

#pragma mark -
#pragma mark Hosts In Session Context Menu handlers

- (IBAction)hostsInSessionCheckAll:(id)sender
{
   NSArray *a = [hostsInSessionController arrangedObjects];
   
   for (id h in a)
   {
      [h setIsSelected:[NSNumber numberWithBool:YES]];
   }
}

- (IBAction)hostsInSessionCheckNone:(id)sender;
{
   NSArray *a = [hostsInSessionController arrangedObjects];
   
   for (id h in a)
   {
      [h setIsSelected:[NSNumber numberWithBool:NO]];
   }
}

- (IBAction)hostsInSessionCheckSelected:(id)sender;
{
   NSArray *a = [hostsInSessionController selectedObjects];
   
   for (id h in a)
   {
      [h setIsSelected:[NSNumber numberWithBool:YES]];
   }
}

- (IBAction)hostsInSessionQueueSelected:(id)sender
{
   // First check the selected sessions, just in case the user forgot...
   [self hostsInSessionCheckSelected:nil];
   
   NSArray *a = [hostsInSessionController arrangedObjects];   
   NSString *currentString = @"";
   NSString *selectedText = nil;

   // Prepend the string to the target combo box
   for (Host *h in a)
   {  
      if ([[h isSelected] isEqualToNumber:[NSNumber numberWithInt:1]])
      {
         if ([h hostname] == nil)
            selectedText = [h ipv4Address];
         else
            selectedText = [h hostname]; 
         
         if ([currentString isEqualToString:@""])
            currentString = [NSString stringWithFormat:@"%@", selectedText];
         else
            currentString = [NSString stringWithFormat:@"%@, %@", selectedText, currentString];
         [sessionTarget setStringValue:currentString];
      }
   }
}


#pragma mark -
#pragma mark Testing

-(IBAction)submitEmailBugReport:(id)sender
{
   
   // This line defines our entire mailto link. Notice that the link is formed
   // like a standard GET query might be formed, with each parameter, subject
   // and body, follow the email address with a ? and are separated by a &.
   // I use the %@ formatting string to add the contents of the lastResult and
   // songData objects to the body of the message. You should change these to
   // whatever information you want to include in the body.
   NSString* mailtoLink = [NSString
                           stringWithFormat:@"mailto:sam@flexistentialist.org?subject=iScrobbler \
                           Bug Report&body=--Please explain the circumstances of the bug \
                           here--\nThanks for contributing!\n\nResult Data \
                           Dump:\n\n"];
   
   // This creates a URL string by adding percent escapes. Since the URL is
   // just being used locally, I don't know if this is always necessary,
   // however I thought it would be a good idea to stick to standards.
   NSURL *url = [NSURL URLWithString:[(NSString*)
                                      CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)mailtoLink,
                                                                              NULL, NULL, kCFStringEncodingUTF8) autorelease]];
   
   // This just opens the URL in the workspace, to be opened up by Mail.app,
   // with data already entered in the subject, to and body fields.
   [[NSWorkspace sharedWorkspace] openURL:url];
   
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
   return NSDragOperationCopy;
}

// -------------------------------------------------------------------------------
//	mainWindowZoom: 
// -------------------------------------------------------------------------------
- (void)mainWindowZoom: (NSNotification *)notification
{    
   // If we are zooming to fullscreen
   
   // Resize hosts sidebar
   NSMutableDictionary *minValues = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:170] forKey:[NSNumber numberWithInt:0]];
   [mainSplitView setMinValues:minValues];
   [mainSplitView setPosition:170 ofDividerAtIndex:0];

//   // Uncollapse sessions subview
//   [self openSessionsInternalView];
   [self performSelector:@selector(openSessionsInternalView) withObject:self afterDelay:0.3];   
   
   // Uncollapse notes subview
   [self openNotesInternalView];
}

// -------------------------------------------------------------------------------
//	mainWindowUnzoom: 
// -------------------------------------------------------------------------------
- (void)mainWindowUnzoom: (NSNotification *)notification
{    
   // If we are zooming to fullscreen
   
   // Resize hosts sidebar
   NSMutableDictionary *minValues = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:120] forKey:[NSNumber numberWithInt:0]];
   [mainSplitView setMinValues:minValues];
   [mainSplitView setPosition:120 ofDividerAtIndex:0];

   // Uncollapse sessions subview
   [self closeSessionsInternalView];
   
   // Uncollapse notes subview
   [self closeNotesInternalView];   
}

- (void)openNotesInternalView
{
   if ([notesInternalView collapsibleSubviewCollapsed] == YES)
      [notesInternalView toggleCollapse:testy];
}

- (void)openSessionsInternalView
{
   if ([sessionsInternalView collapsibleSubviewCollapsed] == YES)   
      [sessionsInternalView toggleCollapse:testy];
}

- (void)closeNotesInternalView
{
   if ([notesInternalView collapsibleSubviewCollapsed] == NO)
      [notesInternalView toggleCollapse:testy];
}

- (void)closeSessionsInternalView
{
   if ([sessionsInternalView collapsibleSubviewCollapsed] == NO)   
      [sessionsInternalView toggleCollapse:testy];
}

- (void)toggleNotesInternalView
{
   [notesInternalView toggleCollapse:testy];
}

- (void)toggleSessionsInternalView
{
   [sessionsInternalView toggleCollapse:testy];   
}

#pragma mark -
#pragma mark Sort Descriptors

// -------------------------------------------------------------------------------
//	Sort Descriptors for the various table views
// -------------------------------------------------------------------------------

// http://fadeover.org/blog/archives/13
- (NSArray *)hostSortDescriptor
{
	if(hostSortDescriptor == nil){
		hostSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"ipv4Address" ascending:YES]];
   }
   
	return hostSortDescriptor;
}

- (void)setHostSortDescriptor:(NSArray *)newSortDescriptor
{
	hostSortDescriptor = newSortDescriptor;
}

- (NSArray *)portSortDescriptor
{
	if(portSortDescriptor == nil){
		portSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES]];
   }
   
	return portSortDescriptor;
}

- (void)setPortSortDescriptor:(NSArray *)newSortDescriptor
{
	portSortDescriptor = newSortDescriptor;
}

- (NSArray *)profileSortDescriptor
{
	if(profileSortDescriptor == nil){
		profileSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"lastAccessDate" ascending:NO]];
   }
   
	return profileSortDescriptor;
}

- (void)setProfileSortDescriptor:(NSArray *)newSortDescriptor
{
	profileSortDescriptor = newSortDescriptor;
}

- (NSArray *)sessionSortDescriptor
{
	if(sessionSortDescriptor == nil){
		sessionSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]];
   }
   
	return sessionSortDescriptor;
}

- (void)setSessionSortDescriptor:(NSArray *)newSortDescriptor
{
	sessionSortDescriptor = newSortDescriptor;
}

- (NSArray *)osSortDescriptor
{
	if(osSortDescriptor == nil){
		osSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO]];
   }
   
	return osSortDescriptor;
}

- (void)setOsSortDescriptor:(NSArray *)newSortDescriptor
{
	osSortDescriptor = newSortDescriptor;
}

- (NSArray *)notesSortDescriptor
{
	if(notesSortDescriptor == nil){
		notesSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES]];
   }
   
	return notesSortDescriptor;
}

- (void)setNotesSortDescriptor:(NSArray *)newSortDescriptor
{
	notesSortDescriptor = newSortDescriptor;
}


@end
