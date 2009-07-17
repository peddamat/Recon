//
//  MyDocument.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright bafoontecha.com 2009 . All rights reserved.
//

#import "MyDocument.h"
#import "SessionManager.h"
#import "SessionController.h"
#import "ArgumentListGenerator.h"

#import "Session.h"
#import "Profile.h"
#import "Port.h"
#import "Host.h"

// For reading interface addresses
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#import "Connection.h"

@class Profile;

@implementation MyDocument

@synthesize hostSortDescriptor;
@synthesize portSortDescriptor;
@synthesize profileSortDescriptor;
@synthesize sessionSortDescriptor;

@synthesize testy;

- (NSString *)applicationSupportFolder {
   
   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
   NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
   return [basePath stringByAppendingPathComponent:@"Recon"];
}

- (id)init 
{
    if (self = [super init])
    {
       sessionManager = [[SessionManager alloc] init];
       interfacesDictionary = [[NSMutableDictionary alloc] init];
       
       NSFileManager *fileManager;
       NSString *applicationSupportFolder = nil;
       NSURL *url;
       NSError *error;
       
       fileManager = [NSFileManager defaultManager];
       applicationSupportFolder = [self applicationSupportFolder];
       if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
          [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
       }
       
       url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"Library.sessions"]];       
  
       NSLog(@"MyDocument: Persistent Store URL: %@",url);
       [self configurePersistentStoreCoordinatorForURL:url ofType:NSSQLiteStoreType error:&error];              
    }
    return self;
}

- (void)dealloc
{
   [sessionManager dealloc];
   [interfacesDictionary dealloc];
   [super dealloc];
}

- (NSPredicate *)testy
{
   NSLog(@"MyDocument: testy");
   if (testy == nil) {
      testy = [NSPredicate predicateWithFormat: @"ANY ports.number == 23"];   
   }
   return testy;
}


- (IBAction)peanut:(id)sender
{
   
//   NSManagedObjectContext *context = [self managedObjectContext];
//   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];   
//   NSEntityDescription *entity = [NSEntityDescription entityForName:@"Host"
//                                             inManagedObjectContext:[self managedObjectContext]];
//   
//   [request setEntity:entity];
//   
//   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY ports.number == 23"];
//   [request setPredicate:predicate];
//   
//   NSError *error = nil;
//   NSArray *array = [context executeFetchRequest:request error:&error];   
//   
//   NSLog(@"MyDoc: Array: %i", [array count]);
   NSLog(@"HIHIHIH");
}




- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];

   [NSApp setServicesProvider:self];
   
   // Register user defaults
//   [self registerDefaults];
   
   // If this is the first run, show Preferences window
//   if ([self hasRun] == FALSE) {
//      [self setRun];      
//      NSLog(@"Hasn't run");      
//   }
   
   // Use Preferences controller to verify nmap binary and log directory are set.
   PrefsController *prefs = [[[PrefsController alloc] init] autorelease];
   [prefs checkPrefs];
   
   // Add some default profiles   
   [self addProfileDefaults];   
   
   // Load queued sessions to session manager
   [self addQueuedSessions];
   
   // Beauty up the profiles drawer
   NSSize mySize = {145, 90};
   [profilesDrawer setContentSize:mySize];
   [profilesDrawer setTrailingOffset:25];
   
   // Open sessions drawer
   [sessionsDrawer toggle:self];      
   [profilesDrawer openOnEdge:NSMinXEdge];
   
   [sessionsTableView setTarget:self];
   [sessionsTableView setDoubleAction:@selector(sessionsTableDoubleClick)];
   [sessionsContextMenu setAutoenablesItems:YES];      
   
   [hostsTableView setTarget:self];
   [hostsTableView setDoubleAction:@selector(hostsTableDoubleClick)];
   
   [resultsPortsTableView setTarget:self];
   [resultsPortsTableView setDoubleAction:@selector(resultsPortsTableDoubleClick)];   
   
   [self getNetworkInterfaces];
   [self populateInterfacePopUp];   
   
   // Setup Queue buttons
   [queueSegmentedControl setTarget:self];   
   [queueSegmentedControl setAction:@selector(segControlClicked:)];   
   
   [mainsubView retain];
   [mainsubView2 retain];
   
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
//   NSLog(@"TOOLBAR");
   
   return YES;
}

// -------------------------------------------------------------------------------
//	awakeFromNib: Initialize UI defaults
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
   NSLog(@"MyDocument: awakeFromNib!");
}

// -------------------------------------------------------------------------------
//	getNetworkInterfaces: 
// -------------------------------------------------------------------------------
- (void)getNetworkInterfaces 
{ 
   //NSString *address = @"error"; 
   struct ifaddrs *interfaces = NULL; 
   struct ifaddrs *temp_addr = NULL; 
   int success = 0; // retrieve the current interfaces - returns 0 on success  
   
   success = getifaddrs(&interfaces); 
   
   if (success == 0)  
   { 
      // Loop through linked list of interfaces  
      temp_addr = interfaces; 
      while(temp_addr != NULL)  
      { 
         if(temp_addr->ifa_addr->sa_family == AF_INET)  
         { 
            [interfacesDictionary setObject:[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)] 
                                     forKey:[NSString stringWithUTF8String:temp_addr->ifa_name]];            
         } 
         temp_addr = temp_addr->ifa_next; 
      } 
   } 

   freeifaddrs(interfaces); 
} 

// -------------------------------------------------------------------------------
//	populateInterfacePopUp: 
// -------------------------------------------------------------------------------
- (void)populateInterfacePopUp
{
   NSMenu *menu = [interfacesPopUp menu];
   int i;
   
   id dictKey;
   NSArray *allKeys = [interfacesDictionary allKeys];   
   NSEnumerator *e = [allKeys objectEnumerator];

   while (dictKey = [e nextObject])
   {
      NSString *dictValue = [interfacesDictionary valueForKey:dictKey];
      
      NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@)",dictKey,dictValue]
                                                  action:@selector(switchToScanView)
                                           keyEquivalent:@""];      
      [mi setTag:++i];
      [menu addItem:mi];
      [mi release];      
   }
   
   [interfacesPopUp selectItemAtIndex:0];   
}

// -------------------------------------------------------------------------------
//	segControlClicked: Segment control is used to manipulate Sessions Queue.
// -------------------------------------------------------------------------------
- (IBAction)segControlClicked:(id)sender
{
   int clickedSegment = [sender selectedSegment];
   
   if (clickedSegment == 0)
      [self dequeueSession:self];
   if (clickedSegment == 1)
      [self processQueue:self];
   if (clickedSegment == 2)
      [self queueSession:self];
}


// -------------------------------------------------------------------------------
//	queueSession: Use current state of the selected Profile and queue a session.              
//   http://arstechnica.com/apple/guides/2009/04/cocoa-dev-the-joy-of-nspredicates-and-matching-strings.ars
// -------------------------------------------------------------------------------
- (IBAction)queueSession:(id)sender 
{   
   NSLog(@"MyDocument: queueSession");
   
   // Read the manual entry textfield, tokenize the string, and pull out
   //  arguments that start with '-', ie. nmap commands
   NSString *nmapCommand  = [nmapCommandTextField stringValue];
   NSArray *parsedNmapCommand = [nmapCommand componentsSeparatedByString:@" "];
   NSArray *commands = [parsedNmapCommand filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith '-'"]];
   
   // Check if the user entered any commands
   if ([commands count] == 0)
   {
      // Retrieve currently selected profile
      Profile *profile = [[profileController selectedObjects] lastObject];
      
      // TODO: Check to make sure input arguments are valid
      [sessionManager queueSessionWithProfile:profile withTarget:[sessionTarget stringValue]];      
   }
   // ... otherwise, parse the input commands and queue the session
   else
   {
      // Make sure the user-specified commands are valid
      ArgumentListGenerator *a = [[ArgumentListGenerator alloc] init];   
      
      if ([a checkArgList:commands] == TRUE)
      {
         // Create a brand spankin' profile
         Profile *profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" 
                                                          inManagedObjectContext:[self managedObjectContext]];
         [profile setName:@"Direct Entry"];
         
         // Populate new profile with command line args
         [a populateProfile:profile withArgString:commands];
         
         // TODO: Check to make sure input arguments are valid
         [sessionManager queueSessionWithProfile:profile withTarget:[parsedNmapCommand lastObject]];         

         // Cleanup
         [[self managedObjectContext] deleteObject:profile];
         [nmapCommandTextField setStringValue:@""];
      }
   }
}

// -------------------------------------------------------------------------------
//	dequeueSession: Use current state of the selected Profile and queue a session.
// -------------------------------------------------------------------------------
- (IBAction)dequeueSession:(id)sender 
{   
   [sessionManager deleteSession:[self selectedUUID]];  
}

// -------------------------------------------------------------------------------
//	processQueue: Begin processing session queue.
// -------------------------------------------------------------------------------
- (IBAction)processQueue:(id)sender
{   
   [sessionManager processQueue];
}

- (void)addQueuedSessions
{
   NSManagedObjectContext *context = [self managedObjectContext];
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];   
   NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session"
                                             inManagedObjectContext:[self managedObjectContext]];
   [request setEntity:entity];
   
   NSError *error = nil;
   NSArray *array = [context executeFetchRequest:request error:&error];

   NSEnumerator *enumerator = [array objectEnumerator];
   id object;
   
   while ((object = [enumerator nextObject])) {
      NSString *status = [object valueForKey:@"status"];
      NSLog(@"%@", status);
//      if ([status compare:@"Queued"] == TRUE)
//         NSLog(@"QUEUED!");
   }
      
}

// -------------------------------------------------------------------------------
//	addProfileDefaults: TODO: This should be moved to the PrefsController.
// -------------------------------------------------------------------------------
- (void)addProfileDefaults
{
   NSManagedObjectContext *context = [self managedObjectContext];
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];   
   NSEntityDescription *entity = [NSEntityDescription entityForName:@"Profile"
                                             inManagedObjectContext:[self managedObjectContext]];
   [request setEntity:entity];
   
   NSError *error = nil;
   NSArray *array = [context executeFetchRequest:request error:&error];
   
   if (array != nil) {
      
      int count = [array count]; // may be 0 if the object has been deleted   
      
      if (count == 0)
      {
         NSManagedObjectContext *context = [self managedObjectContext]; 
         Profile *profileParent = nil; 
         
         // Add Defaults parent folder
         profileParent = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
         [profileParent setValue: @"Defaults" forKey: @"name"]; 
         [profileParent setIsEnabled:NO];
         
         Profile *profile = nil; 
         
         // Add a few defaults
         profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
         [profile setValue: @"Ping Scan" forKey: @"name"]; 
         [profile setEnableAggressive:[NSNumber numberWithInt:1]];
         
         [profile setValue:profileParent forKey:@"parent"];
         
         profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
         [profile setValue: @"OS Detection" forKey: @"name"]; 
         [profile setEnableAggressive:[NSNumber numberWithInt:1]];         
         [profile setValue:profileParent forKey:@"parent"];
         
         
         // Add Saved Sessions parent folder
         profileParent = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
         [profileParent setValue: @"Saved Sessions" forKey: @"name"]; 
         [profileParent setIsEnabled:NO];         
         
      }
   }
}

// -------------------------------------------------------------------------------
//	Preference Window key-handlers
// -------------------------------------------------------------------------------

- (IBAction)showPrefWindow:(id)sender {
   // First update the Prefs window
   [self updatePrefsWindow];
   
   // Then display as sheet
   [NSApp beginSheet:prefWindow
      modalForWindow:[mainView window]
       modalDelegate:nil
      didEndSelector:NULL
         contextInfo:NULL];
}
- (IBAction)endPrefWindow:(id)sender {
   // Verify user-specified settings are valid
   
   // Then store them to User Defaults 
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   NSString *nmapBinaryLocation = [nmapBinaryString stringValue];
   NSString *savedSessionsDirectory = [sessionDirectoryString stringValue];
   
//   [defaults setObject:nmapBinaryLocation forKey:BAFNmapBinLoc];
//   [defaults setObject:savedSessionsDirectory forKey:BAFSesSaveDir];
      
   // Return to normal event handling
   [NSApp endSheet:prefWindow];
   
   // Hide the sheet
   [prefWindow orderOut:sender];
}

// -------------------------------------------------------------------------------
//	Profile Split View key-handlers
// -------------------------------------------------------------------------------

- (void) collapseProfileView {
   if ([profileView collapsibleSubviewCollapsed] == FALSE)
      [profileView toggleCollapse:profileButton];      
}
- (void) expandProfileView {
   if ([profileView collapsibleSubviewCollapsed] == TRUE)
      [profileView toggleCollapse:profileButton];      
}
- (IBAction) toggleProfileView:(id)sender {
//   [profileView toggleCollapse:profileButton];   
   [profilesDrawer toggle:self];   
}

// -------------------------------------------------------------------------------
//	View togglers
// -------------------------------------------------------------------------------

// -------------------------------------------------------------------------------
//	switchToScanView: Replace Inspector view with Scan view
// -------------------------------------------------------------------------------
- (IBAction)switchToScanView:(id)sender
{   
   [sessionsDrawer open];
   [profilesDrawer open];   
   
   [self swapView:mainsubView2 withSubView:mainsubView inContaningView:mainView];   
   
}

// -------------------------------------------------------------------------------
//	switchToInspectorView: Replace Scan view with Inspector view
// -------------------------------------------------------------------------------
- (IBAction)switchToInspectorView:(id)sender
{
   [sessionsDrawer close];
   [profilesDrawer close];
   
   [self swapView:mainsubView withSubView:mainsubView2 inContaningView:mainView];
   
}

// -------------------------------------------------------------------------------
//	swapView: Swaps view with animated resize
// -------------------------------------------------------------------------------
- (void)swapView:(NSView *)oldSubview withSubView:(NSView *)newSubview inContaningView:(NSView *)containerView
{
   NSWindow *w = [containerView window];
   
   // Compute the new window frame
   NSSize currentSize = [oldSubview frame].size;
   NSSize newSize = [newSubview frame].size;
   float deltaWidth = newSize.width - currentSize.width;
   float deltaHeight = newSize.height - currentSize.height;
   NSRect windowFrame = [w frame];
   windowFrame.size.height += deltaHeight;
   windowFrame.origin.y -= deltaHeight;
   windowFrame.size.width += deltaWidth;
   
   // Clear the box for resizing
   [w setFrame:windowFrame
       display:YES
       animate:YES];
   
   NSPoint myPoint = {0, 34};
   [newSubview setFrameOrigin:myPoint];
   [containerView replaceSubview:oldSubview with:newSubview];   
}

// -------------------------------------------------------------------------------
//	Main Menu key-handlers
// -------------------------------------------------------------------------------

- (IBAction) toggleSettings:(id)sender {
   [mainTabView selectTabViewItemAtIndex:0];
   [self switchToScanView:self];
}
- (IBAction) toggleResults:(id)sender {
   [mainTabView selectTabViewItemAtIndex:1];
   [self switchToScanView:self];   
}
- (IBAction) toggleSessionsDrawer:(id)sender {
   [sessionsDrawer toggle:self];    
}


// -------------------------------------------------------------------------------
//	Session Drawer Menu key-handlers
// -------------------------------------------------------------------------------

- (Session *)clickedUUID
{
   // Find clicked row from sessionsTableView
   NSInteger clickedRow = [sessionsTableView clickedRow];
   // Get selected object from sessionsController 
   return [[sessionsController arrangedObjects] objectAtIndex:clickedRow];
}

- (Session *)selectedUUID
{
   // Find clicked row from sessionsTableView
   NSInteger selectedRow = [sessionsTableView selectedRow];
   // Get selected object from sessionsController 
   return [[sessionsController arrangedObjects] objectAtIndex:selectedRow];   
}

- (IBAction) sessionDrawerRun:(id)sender
{
   NSLog(@"MyDocument: launching session");
   int numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   
   if (numberOfSelectedRows > 1)
   {
      NSIndexSet *selectedRows = [sessionsTableView selectedRowIndexes];
      NSArray *selectedSessions = [[sessionsController arrangedObjects] objectsAtIndexes:selectedRows];   
      
      id session;
      NSEnumerator *e = [selectedSessions objectEnumerator];
      
      while (session = [e nextObject])
         [sessionManager launchSession:session];         
   }
   else 
   {
      NSInteger clickedRow = [sessionsTableView clickedRow];
      // Get selected object from sessionsController 
      [sessionManager launchSession:[[sessionsController arrangedObjects] objectAtIndex:clickedRow]];      
   }
}
- (IBAction) sessionDrawerRunCopy:(id)sender
{
   NSLog(@"MyDocument: sessionDrawerRunCopy - NOT IMPLEMENTED!");
}
- (IBAction) sessionDrawerAbort:(id)sender
{
   NSLog(@"MyDocument: Aborting session");
   [sessionManager abortSession:[self clickedUUID]];
}
- (IBAction) sessionDrawerRemove:(id)sender
{
   NSLog(@"MyDocument: Removing session");
   
   int numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   
   if (numberOfSelectedRows > 1)
   {
      NSIndexSet *selectedRows = [sessionsTableView selectedRowIndexes];
      NSArray *selectedSessions = [[sessionsController arrangedObjects] objectsAtIndexes:selectedRows];   
      
      id session;
      NSEnumerator *e = [selectedSessions objectEnumerator];
      
      while (session = [e nextObject])
         [sessionManager deleteSession:session];         
   }
   else 
   {
      NSInteger clickedRow = [sessionsTableView clickedRow];
      // Get selected object from sessionsController 
      [sessionManager deleteSession:[[sessionsController arrangedObjects] objectAtIndex:clickedRow]];      
   }
}
- (IBAction) sessionDrawerShowInFinder:(id)sender
{
   // Retrieve currently selected session
   NSString *savedSessionsDirectory = [PrefsController applicationSessionsFolder];  
   NSLog(@"%@", [self clickedUUID]);
   [[NSWorkspace sharedWorkspace] openFile:[savedSessionsDirectory stringByAppendingPathComponent:[[self clickedUUID] UUID]]
                           withApplication:@"Finder"];

}


// -------------------------------------------------------------------------------
//	Table click handlers
// -------------------------------------------------------------------------------

- (void)hostsTableDoubleClick
{
   // If user double-clicks on a Host menu item, switch to results view
   [self toggleResults:self];
}

- (void)resultsPortsTableDoubleClick
{
   // Find clicked row from sessionsTableView
   NSInteger selectedRow = [resultsPortsTableView selectedRow];
   // Get selected object from sessionsController 
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
}

// Sessions Drawer click-handlers
- (void)sessionsTableDoubleClick
{
   NSLog(@"MyDocument: doubleClick!");
   
   // Retrieve currently selected session
   Session *selectedSession = [[sessionsController selectedObjects] lastObject]; 
   
   if (selectedSession != nil) {
      // Retrieve currently selected profile
      Profile *storedProfile = [selectedSession profile];
//      [profileController setContent:[NSArray arrayWithObject:storedProfile]];
      
      //   [[profileController selectedObjects] lastObject];
   }
}

// Enable/Disable menu depending on context
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
   BOOL enabled = NO;
   
   if (
    ([menuItem action] == @selector(sessionDrawerRun:)) ||
//    ([menuItem action] == @selector(sessionDrawerRunCopy:)) ||
    ([menuItem action] == @selector(sessionDrawerAbort:)) ||       
    ([menuItem action] == @selector(sessionDrawerRemove:)) ||
    ([menuItem action] == @selector(sessionDrawerShowInFinder:))       
    )
   {
      NSInteger clickedRow = [sessionsTableView clickedRow];
      if (clickedRow == -1)
         enabled = NO;
      else
         enabled = YES;
   } 
   else
   {
      enabled = [super validateMenuItem:menuItem];
   }
  
   return enabled;
}

// Handle context menu clicks in Sessions TableView
- (void)menuNeedsUpdate:(NSMenu *)menu 
{
//   NSInteger clickedRow = [sessionsTableView clickedRow];
//   NSInteger selectedRow = [sessionsTableView selectedRow];
//   NSInteger numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   //(NSIndexSet *)selectedRowIndexes = [sessionsTableView selectedRowIndexes];
   
   // If clickedRow == -1, the user hasn't clicked on a session
   
   // TODO: If Sessions Context Menu
   if (menu == sessionsContextMenu) {
         
   }
   else
      NSLog(@"MyDocument: fart!");      
   
   // TODO: If Hosts Context Menu
   
   // TODO: If Ports in Host Context Menu
   
   // TODO: If Ports Context Menu
   
   // TODO: If Profiles Context Menu
   
//   [sessionsContextMenu update];
}

- (IBAction)setuidNmap:(id)sender
{
   [self rootNmap];
}

- (IBAction)unsetuidNmap:(id)sender
{
   [self unrootNmap];
}



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
		profileSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
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
		sessionSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES]];
   }
   
	return sessionSortDescriptor;
}

- (void)setSessionSortDescriptor:(NSArray *)newSortDescriptor
{
	sessionSortDescriptor = newSortDescriptor;
}

- (NSString *)windowNibName 
{
   return @"MyDocument";
}










- (IBAction)saveDocument:(id)sender
{
   NSLog(@"SAVY?");
}

- (IBAction)saveDocumentTo:(id)sender
{
   NSLog(@"SAVY?");
}
- (IBAction)saveDocumentAs:(id)sender
{
   NSLog(@"SAVY?");
}


// -------------------------------------------------------------------------------
//	controlTextDidEndEditing
// -------------------------------------------------------------------------------
- (void)controlTextDidEndEditing:(NSNotification *)obj
{
//   NSLog(@"%@", obj);
}

- (BOOL)isDocumentEdited
{
   return NO;
//   NSLog(@"EDIT!");
}

//- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
//{	
//
//	[[self managedObjectContext] commitEditing];
//	[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
//}


// -------------------------------------------------------------------------------
//	applicationShouldTerminate: Saves the managed object context before close
// -------------------------------------------------------------------------------
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
   
   NSLog(@"QUITTING APASD");
   
   NSError *error;
   int reply = NSTerminateNow;
   NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
   
   if (managedObjectContext != nil) {
      if ([managedObjectContext commitEditing]) {
         if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            
            // This error handling simply presents error information in a panel with an 
            // "Ok" button, which does not include any attempt at error recovery (meaning, 
            // attempting to fix the error.)  As a result, this implementation will 
            // present the information to the user and then follow up with a panel asking 
            // if the user wishes to "Quit Anyway", without saving the changes.
            
            // Typically, this process should be altered to include application-specific 
            // recovery steps.  
            
            BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
            
            if (errorResult == YES) {
               reply = NSTerminateCancel;
            } 
            
            else {
               
               int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
               if (alertReturn == NSAlertAlternateReturn) {
                  reply = NSTerminateCancel;	
               }
            }
         }
      } 
      
      else {
         reply = NSTerminateCancel;
      }
   }

//   exit(0);
   return reply;
}

@end
