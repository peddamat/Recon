//
//  MyDocument.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright bafoontecha.com 2009 . All rights reserved.
//

#import "MyDocument.h"
#import "SessionManager.h"
#import "SessionController.h"
#import "ArgumentListGenerator.h"

#import "Host.h"
#import "Port.h"
#import "Profile.h"
#import "Session.h"
#import "OperatingSystem.h"

#import "Connection.h"

// For reading interface addresses
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation MyDocument

@synthesize hostSortDescriptor;
@synthesize portSortDescriptor;
@synthesize profileSortDescriptor;
@synthesize sessionSortDescriptor;

@synthesize testy;


- (id)init 
{
    if (self = [super init])
    {
       // The Session Manager is a singleton instance
       sessionManager = [SessionManager sharedSessionManager];
       [sessionManager setContext:[self managedObjectContext]];
       
       interfacesDictionary = [[NSMutableDictionary alloc] init];
       
       NSFileManager *fileManager;
       NSString *applicationSupportFolder = nil;
       NSURL *url;
       NSError *error;
       
       fileManager = [NSFileManager defaultManager];
       applicationSupportFolder = [PrefsController applicationSupportFolder];
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
   [sessionManager release];
   [interfacesDictionary release];
   
   [nmapErrorTimer invalidate];
   [nmapErrorTimer release];
   
   [nmapErrorTimer invalidate];
   [nmapErrorTimer release];
   
   [mainsubView release];
   [mainsubView2 release];   
   [super dealloc];
}

// -------------------------------------------------------------------------------
//	displayName: Override NSPersistentDocument window title
// -------------------------------------------------------------------------------
- (NSString *)displayName
{
   return @"Recon";
}

// -------------------------------------------------------------------------------
//	windowControllerDidLoadNib: This is where we perform most of the initial app
//                             setup.
// -------------------------------------------------------------------------------
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
      
   prefsController = [PrefsController sharedPrefsController];
   [prefsController displayOnFirstRun];
   
   // Add some default profiles   
   [self addProfileDefaults];   
   
   // Load queued sessions in the persistent store into session manager
   [self addQueuedSessions];
   
   // Beauty up the profiles drawer
   NSSize mySize = {145, 90};
   [profilesDrawer setContentSize:mySize];
   [profilesDrawer setTrailingOffset:25];
   
   // Open sessions drawer
   [sessionsDrawer toggle:self];      
   [profilesDrawer openOnEdge:NSMinXEdge];
   
   // Set up click-handlers for the Sessions Drawer
   [sessionsTableView setTarget:self];
   [sessionsTableView setDoubleAction:@selector(sessionsTableDoubleClick)];
   [sessionsContextMenu setAutoenablesItems:YES];      
   
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
   
   // Setup up interfaces Popup Button
   [self getNetworkInterfaces];
   [self populateInterfacePopUp];   
   
   // Setup Queue buttons
   [queueSegmentedControl setTarget:self];   
   [queueSegmentedControl setAction:@selector(segControlClicked:)];   
   
   [mainsubView retain];
   [mainsubView2 retain];
   
   nmapErrorTimer = [[NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(expandProfileView:)
                                                    userInfo:nil
                                                     repeats:YES] retain]; 
}

- (void)expandProfileView:(NSTimer *)aTimer
{
   [nmapErrorTimer invalidate];
   [profilesOutlineView expandItem:nil expandChildren:YES];   
   [profileController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
//   NSLog(@"TOOLBAR");
   
   return YES;
}

// -------------------------------------------------------------------------------
//	awakeFromNib: Everything in here was moved to windowControllerDidLoadNib, since
//               awakeFromNib tends to be called after Panels are displayed.
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
   
   for (NSString *dictKey in [interfacesDictionary allKeys])
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
   NSArray *nmapFlags = [parsedNmapCommand filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith '-'"]];
   
   // Check if the user entered any commands
   if ([nmapFlags count] == 0)
   {      
      // TODO: Check to make sure input arguments are valid
      [sessionManager queueSessionWithProfile:[[profileController selectedObjects] lastObject]
                                   withTarget:[sessionTarget stringValue]];      
   }
   // ... otherwise, parse the input commands and queue the session
   else
   {
      // Make sure the user-specified commands are valid
      ArgumentListGenerator *a = [[ArgumentListGenerator alloc] init];   
      
      if ([a areFlagsValid:nmapFlags] == YES)
      {
         // Create a brand spankin' profile
         Profile *profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" 
                                                          inManagedObjectContext:[self managedObjectContext]];
         
         // Populate new profile with command line args
         [a populateProfile:profile 
              withArgString:nmapFlags];
         
         // TODO: Check to make sure input arguments are valid
         [sessionManager queueSessionWithProfile:profile 
                                      withTarget:[parsedNmapCommand lastObject]];         

         // Cleanup
         [[self managedObjectContext] deleteObject:profile];
         [nmapCommandTextField setStringValue:@""];
      }
      // Flash textfield to indicate entry error
      else
      {
         nmapErrorCount = 1.0;
         nmapErrorTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05
                                                   target:self
                                                 selector:@selector(indicateEntryError:)
                                                 userInfo:nil
                                                  repeats:YES] retain]; 
      }
   }
}

// -------------------------------------------------------------------------------
//	indicateEntryError: Timer helper-function indicating nmap command entry error
// -------------------------------------------------------------------------------
- (void)indicateEntryError:(NSTimer *)aTimer
{
   nmapErrorCount -= 0.04;
   if (nmapErrorCount <= 0) {
      [nmapErrorTimer invalidate];
      [nmapCommandTextField setTextColor:[NSColor blackColor]];  
      return;
   }      
   
   [nmapCommandTextField setTextColor:[NSColor colorWithDeviceRed:nmapErrorCount green:0 blue:0 alpha:1]];
}         


// -------------------------------------------------------------------------------
//	dequeueSession: Use current state of the selected Profile and queue a session.
// -------------------------------------------------------------------------------
- (IBAction)dequeueSession:(id)sender 
{   
   [sessionManager deleteSession:[self selectedSessionInDrawer]];  
}

// -------------------------------------------------------------------------------
//	processQueue: Begin processing session queue.
// -------------------------------------------------------------------------------
- (IBAction)processQueue:(id)sender
{   
   [sessionManager processQueue];
}

// -------------------------------------------------------------------------------
//	addQueuedSessions: When the application loads, previous sessions are loaded
//                    from the persistent store.  We have to add queued sessions
//                    to the Session Manager, so continuity in the user experience
//                    is maintained.
// -------------------------------------------------------------------------------
- (void)addQueuedSessions
{
   NSManagedObjectContext *context = [self managedObjectContext];
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];   
   NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session"
                                             inManagedObjectContext:[self managedObjectContext]];
   [request setEntity:entity];
   
   NSPredicate *predicate = [NSPredicate predicateWithFormat:
                             @"(status LIKE[c] 'Queued')"];
   
   [request setPredicate:predicate];   
   
   NSError *error = nil;
   NSArray *array = [context executeFetchRequest:request error:&error];

   for (id object in array)
   {
      [sessionManager queueExistingSession:object];
   }
      
   
   // This should probably be moved to it's own method, buuuuut...
   predicate = [NSPredicate predicateWithFormat:
                             @"(status != 'Queued') AND (status != 'Done') AND (status != 'Aborted')"];
   
   [request setPredicate:predicate];   
   
   array = [context executeFetchRequest:request error:&error];

   // Set incomplete scans to 'Aborted'
   for (id object in array)
   {
      [object setStatus:@"Aborted"];
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
//	addProfile: Add a new profile to the Persistent Store
// -------------------------------------------------------------------------------
- (IBAction)addProfile:(id)sender
{
   NSManagedObjectContext *context = [self managedObjectContext];
   NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];   
   NSEntityDescription *entity = [NSEntityDescription entityForName:@"Profile"
                                             inManagedObjectContext:[self managedObjectContext]];
   
   [request setEntity:entity];
   
   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = 'User Profiles'"];
   [request setPredicate:predicate];
   
   NSError *error = nil;
   NSArray *array = [context executeFetchRequest:request error:&error];   
   Profile *profileParent = [array lastObject];
   
   if (profileParent == nil)
   {
      profileParent = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
      [profileParent setName:@"User Profiles"];
   }
   
   Profile *profile = nil; 
   
   // Add a few defaults
   profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
   [profile setValue: @"New Profile" forKey: @"name"]; 
   [profile setValue:profileParent forKey:@"parent"];
   
   // Expand the profiles window
   [profilesOutlineView expandItem:nil expandChildren:YES];   
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
- (void)swapView:(NSView *)oldSubview 
     withSubView:(NSView *)newSubview 
 inContaningView:(NSView *)containerView
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
//	Session Drawer Menu key-handlers
// -------------------------------------------------------------------------------

- (Session *)clickedSessionInDrawer
{
   // Find clicked row from sessionsTableView
   NSInteger clickedRow = [sessionsTableView clickedRow];
   // Get selected object from sessionsController 
   return [[sessionsController arrangedObjects] objectAtIndex:clickedRow];
}

- (Session *)selectedSessionInDrawer
{
   // Find clicked row from sessionsTableView
   NSInteger selectedRow = [sessionsTableView selectedRow];
   // Get selected object from sessionsController 
   return [[sessionsController arrangedObjects] objectAtIndex:selectedRow];   
}

- (IBAction)sessionDrawerRun:(id)sender
{
   NSLog(@"MyDocument: launching session");
   int numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   
   if (numberOfSelectedRows > 1)
   {
      NSIndexSet *selectedRows = [sessionsTableView selectedRowIndexes];
      NSArray *selectedSessions = [[sessionsController arrangedObjects] objectsAtIndexes:selectedRows];   
            
      for (id session in selectedSessions)
         [sessionManager launchSession:session];         
   }
   else 
   {
      NSInteger clickedRow = [sessionsTableView clickedRow];
      // Get selected object from sessionsController 
      [sessionManager launchSession:[[sessionsController arrangedObjects] objectAtIndex:clickedRow]];      
   }
}
- (IBAction)sessionDrawerRunCopy:(id)sender
{
   NSLog(@"MyDocument: sessionDrawerRunCopy - NOT IMPLEMENTED!");
}
- (IBAction) sessionDrawerAbort:(id)sender
{
   NSLog(@"MyDocument: Aborting session");
   
   int numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   
   if (numberOfSelectedRows > 1)
   {
      NSIndexSet *selectedRows = [sessionsTableView selectedRowIndexes];
      NSArray *selectedSessions = [[sessionsController arrangedObjects] objectsAtIndexes:selectedRows];   
      
      for (id session in selectedSessions)
         [sessionManager abortSession:session];         
   }
   else 
   {
      NSInteger clickedRow = [sessionsTableView clickedRow];
      // Get selected object from sessionsController 
      [sessionManager abortSession:[[sessionsController arrangedObjects] objectAtIndex:clickedRow]];      
   }
}
- (IBAction) sessionDrawerRemove:(id)sender
{
   NSLog(@"MyDocument: Removing session");
   
   int numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   
   if (numberOfSelectedRows > 1)
   {
      NSIndexSet *selectedRows = [sessionsTableView selectedRowIndexes];
      NSArray *selectedSessions = [[sessionsController arrangedObjects] objectsAtIndexes:selectedRows];   
      
      for (id session in selectedSessions)
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
   NSLog(@"%@", [self clickedSessionInDrawer]);
   [[NSWorkspace sharedWorkspace] openFile:[savedSessionsDirectory stringByAppendingPathComponent:[[self clickedSessionInDrawer] UUID]]
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

- (void)portsTableDoubleClick
{
   // Get selected port
   Port *selectedPort = [[portsInSessionController selectedObjects] lastObject];
   // Get host for selected port
   Host *selectedHost = selectedPort.host;
   
   [hostsInSessionController setSelectedObjects:[NSArray arrayWithObject:selectedHost]];
   // If user double-clicks on a Host menu item, switch to results view
   [self toggleResults:self];
}

- (void)osesTableDoubleClick
{
   // Get selected port
   OperatingSystem *selectedOs = [[osesInSessionController selectedObjects] lastObject];
   // Get host for selected port
   Host *selectedHost = selectedOs.host;
   
   [hostsInSessionController setSelectedObjects:[NSArray arrayWithObject:selectedHost]];
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
   
   // TODO: Parse the port name for services running on non-standard ports
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
//	Menu click handlers
// -------------------------------------------------------------------------------

// Enable/Disable menu depending on context
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
   BOOL enabled = NO;
   
   if (
    ([menuItem action] == @selector(sessionDrawerRun:)) ||
    ([menuItem action] == @selector(sessionDrawerRunCopy:)) ||
    ([menuItem action] == @selector(sessionDrawerAbort:)) ||       
    ([menuItem action] == @selector(sessionDrawerRemove:)) ||
    ([menuItem action] == @selector(sessionDrawerShowInFinder:))       
    )
   {
      NSInteger clickedRow = [sessionsTableView clickedRow];
      if (clickedRow == -1) {
         enabled = NO;
      }
      else 
      {
         enabled = YES;
         Session *s = [self clickedSessionInDrawer];
         
//         // Only enable Abort if session is running
//         if (
//             ([menuItem action] == @selector(sessionDrawerAbort:)) &&
//             ([s status] != @"Queued")
//            )         
//         {
//            NSLog(@"1");
//            enabled = NO;
//         }
//         
//         // Only enable Run if session is not running
//         else if (([menuItem action] == @selector(sessionDrawerRun:)) &&
//                 ([s status] != @"Queued"))
//         {
//
//            enabled = NO;
//         }
      }
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
   if (menu == sessionsContextMenu) 
   {
      Session *s = [self clickedSessionInDrawer];
//      if ([s status] == @"
   }
   else
   {
      NSLog(@"MyDocument: fart!");      
   
   // TODO: If Hosts Context Menu
   
   // TODO: If Ports in Host Context Menu
   
   // TODO: If Ports Context Menu
   
   // TODO: If Profiles Context Menu
   
//   [sessionsContextMenu update];
   }
}


// -------------------------------------------------------------------------------
//	Hands this functionality off to the PrefsController
// -------------------------------------------------------------------------------

- (IBAction)setuidNmap:(id)sender
{
   [PrefsController rootNmap];
}
- (IBAction)unsetuidNmap:(id)sender
{
   [PrefsController unrootNmap];
}
- (IBAction)showPrefWindow:(id)sender
{
   [prefsController showPrefWindow:self];
}


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


- (NSString *)windowNibName 
{
   return @"MyDocument";
}

// -------------------------------------------------------------------------------
//	NSDocument functions that we can potentially override
// -------------------------------------------------------------------------------

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

// Overriding this allows us to create the illusion of Autosave
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
   
   NSLog(@"MyDocument: Closing main window");
   
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

// -------------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed: Kills application properly
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
   return TRUE;
}

// -------------------------------------------------------------------------------
//	testy: Test function for playing around with predicates
// -------------------------------------------------------------------------------
- (NSPredicate *)testy
{
   NSLog(@"MyDocument: testy");
   Session *session = [self selectedSessionInDrawer];
   if (testy == nil) {
      testy = [NSPredicate predicateWithFormat: @"ANY session == %@", session];   
   }
   return testy;
}

// -------------------------------------------------------------------------------
//	peanut: Test function for playing around with predicates
// -------------------------------------------------------------------------------
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

@end
