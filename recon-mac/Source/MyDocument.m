//
//  MyDocument.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright bafoontecha.com 2009 . All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

#import "MyDocument.h"
#import "SessionManager.h"
#import "ArgumentListGenerator.h"

// Helper categories from the interwebs
#import "NSManagedObjectContext-helper.h"

#import "Profile.h"
#import "Session.h"
#import "HostNote.h"


@implementation MyDocument

@synthesize workspacePlaceholder;

- (id)init 
{
    if (self = [super init])
    {
       // Insert initialization code here...
       
    }
    return self;
}

- (void)dealloc
{
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc removeObserver:self];   
   
   [sessionManager release];
   
   [nmapErrorTimer invalidate];
   [nmapErrorTimer release];
   
   [nmapErrorTimer invalidate];
   [nmapErrorTimer release];
   
   [viewControllers release];   
   [super dealloc];
}

// -------------------------------------------------------------------------------
//	displayName: Override NSPersistentDocument window title
// -------------------------------------------------------------------------------
- (NSString *)displayName
{
   return @"Recon.";
}

// -------------------------------------------------------------------------------
//	awakeFromNib: Everything in here was moved to windowControllerDidLoadNib, since
//               awakeFromNib tends to be called after Panels are displayed.
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
   
   // Store the current frame
//   standardWindowRect = [mainWindow frame];   
   standardWindowRect = NSMakeRect(445, 391, 700, 450);
}

// -------------------------------------------------------------------------------
//	windowControllerDidLoadNib: This is where we perform most of the initial app
//                             setup.
// -------------------------------------------------------------------------------
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
   [NSApp setDelegate: self];
   
   //ANSLog(@"windowControllerDidLoadNib");
      
   sessionManager = [SessionManager sharedSessionManager];
   
   [sessionManager setSessionsArrayController:sessionsArrayController];   
   
   [super windowControllerDidLoadNib:windowController];
         
   [modeSwitchBar setSelectedSegment:0];
   
   [NSApp setServicesProvider:self];

   // Grab a copy of the Prefs Controller
   prefsController = [PrefsController sharedPrefsController];
   
   // Listen for user defaults updates from Prefs Controller
   [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(updateSupportFolder:)
    name:@"BAFupdateSupportFolder"
    object:prefsController];   
         
   NSSize mySize2 = {145, 147};
   [sessionsDrawer setContentSize:mySize2];   
   
   // If first run, display welcome screen
   if ([prefsController hasReconRunBefore] == NO)
   {      
      [sessionsDrawer close];
      [notesDrawer close];

      [[NSNotificationCenter defaultCenter]
       addObserver:self
       selector:@selector(finishFirstRun:)
       name:@"BAFfinishFirstRun"
       object:prefsController];   
      
      [prefsController displayWelcomeWindow];      
   }
   else
   {
      [sessionsDrawer open];
      [notesDrawer open];
      
      // Load up Persistent Store
      NSError *error;
      NSURL *url = [NSURL fileURLWithPath: [[prefsController reconSupportFolder]
                                     stringByAppendingPathComponent: @"Library.sessions"]];       
      
      // Set a custom Persistent Store location
      [self configurePersistentStoreCoordinatorForURL:url ofType:NSSQLiteStoreType error:&error];              
      
      // Add some default scanning profiles   
      [self addDefaultProfiles];   

      // Load queued sessions in the persistent store into session manager
      [self addQueuedSessions];
   }

   // Set up click-handlers for the Sessions Drawer
   [sessionsTableView setTarget:self];
   [sessionsTableView setDoubleAction:@selector(sessionsTableDoubleClick)];
   [sessionsTableView setAutosaveTableColumns:YES];   
   [sessionsContextMenu setAutoenablesItems:YES];      
   
   // Setup TableView for drag-and-drop
   [sessionsTableView registerForDraggedTypes:
    [NSArray arrayWithObjects:NSStringPboardType, nil]];
      
   // Setup Queue buttons
   [queueSegmentedControl setTarget:self];   
   [queueSegmentedControl setAction:@selector(segControlClicked:)];   
      
   [[self managedObjectContext] setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];   
   
   
   //------------------------------------------------------| Initialize view controllers
   
   viewControllers = [[NSMutableArray alloc] init];
   
   BasicViewController *vc;
   vc = [[BasicViewController alloc] init];
   [vc setManagedObjectContext:[self managedObjectContext]];
   [vc setSessionsArrayController:sessionsArrayController];
   [vc setProfilesArrayController:profilesArrayController];
   [vc setNotesInHostArrayController:notesInHostArrayController];   
   [vc setHostsInSessionArrayController:hostsInSessionArrayController];      

   // We have to patch the responder chain to make sure
   //  the AdvancedViewController menu items validate
	NSResponder * aNextResponder = [windowController nextResponder];
	[windowController setNextResponder:vc];
	[vc setNextResponder:aNextResponder];
   
   [vc setWorkspacePlaceholder:workspacePlaceholder];
   [viewControllers addObject:vc];   
   [vc release];       
   
   vc = [[AdvancedViewController alloc] init];
   [vc setManagedObjectContext:[self managedObjectContext]];
   [vc setSessionsArrayController:sessionsArrayController];   
   [vc setProfilesArrayController:profilesArrayController];   
   [vc setNotesInHostArrayController:notesInHostArrayController];    
   [vc setHostsInSessionArrayController:hostsInSessionArrayController];         
   [vc setWorkspacePlaceholder:workspacePlaceholder];
   [viewControllers addObject:vc];

   // Patch in the AdvancedViewController
   aNextResponder = [windowController nextResponder];
	[windowController setNextResponder:vc];
	[vc setNextResponder:aNextResponder];
   
   [vc release];              
   
   vc = [[SettingsViewController alloc] init];
   [vc setManagedObjectContext:[self managedObjectContext]];
   [vc setSessionsArrayController:sessionsArrayController];   
   [vc setProfilesArrayController:profilesArrayController];   
   [vc setNotesInHostArrayController:notesInHostArrayController]; 
   [vc setHostsInSessionArrayController:hostsInSessionArrayController];       
   [vc setWorkspacePlaceholder:workspacePlaceholder];
   [viewControllers addObject:vc];
   [vc release];                        
   
   //------------------------------------------------------| Set-up Workspace
   
   // Grab Basic view from controller
   vc = [viewControllers objectAtIndex:0];

   NSView *workspaceBasicContent = [vc view];
   
   [workspaceBasicContent setFrame:[workspacePlaceholder frame]];
   [workspacePlaceholder addSubview:workspaceBasicContent];
   
   NSView *targetBarBasicContent = [vc targetBarBasicContent];
   
   [targetBarBasicContent setFrame:[targetBarPlaceholder frame]];
   [targetBarPlaceholder addSubview:targetBarBasicContent];
   
   [notesSideBarContent setFrame:[notesSideBarPlaceholder bounds]];
   [notesSideBarPlaceholder addSubview:notesSideBarContent];
   
   [targetBarPlaceholder setWantsLayer:YES];
      
   closedDrawers = NO;
}

- (void)displayViewController:(ManagingViewController *)vc
{
   // Try to end editing
   NSWindow *w = [workspacePlaceholder window];
   BOOL ended = [w makeFirstResponder:w];
   if (!ended) {
      NSBeep();
      return;
   }
}

#pragma mark -
#pragma mark First run handlers

// -------------------------------------------------------------------------------
//	updateSupportFolder: If the user updates the output folder in the Prefs Controller
//                      we've gotta relocate the Persistent Store.
// -------------------------------------------------------------------------------
- (void)updateSupportFolder:(NSNotification *)notification
{
   NSError *error;   
   
   NSURL *url = [NSURL fileURLWithPath: [[prefsController reconSupportFolder]
                                         stringByAppendingPathComponent: @"Library.sessions"]];       
   
   // Grab store coordinator
   NSPersistentStoreCoordinator *currentPersistentStoreCoordinator =
   [[self managedObjectContext] persistentStoreCoordinator];
   
   // Grab current persistent store
   NSArray *persistentStores = [currentPersistentStoreCoordinator persistentStores];
   
   // If this isn't the first time running Recon, clean up...
   if ([persistentStores count] != 0)
   {
      [[self managedObjectContext] save:&error];
      
      // Remove current persistent store
      [currentPersistentStoreCoordinator removePersistentStore:[persistentStores lastObject] error:&error];
   }
   
   // Set a custom Persistent Store location
   [self configurePersistentStoreCoordinatorForURL:url ofType:NSSQLiteStoreType error:&error];              
   
   // Add some default profiles   
   [self addDefaultProfiles];   
   
   // Load queued sessions in the persistent store into session manager
   [self addQueuedSessions];   
}


// -------------------------------------------------------------------------------
//	finishFirstRun: BEAUTIFIER FUNCTION.  The Welcome window looks better when the
//                 drawers are closed, so we open them after the user dismisses the
//                 window.
// -------------------------------------------------------------------------------
- (void)finishFirstRun:(NSNotification *)notification
{
   NSLog(@"Finish first run");
   
   // Load up Persistent Store
   NSError *error;
   NSURL *url = [NSURL fileURLWithPath: [[prefsController reconSupportFolder]
                                         stringByAppendingPathComponent: @"Library.sessions"]];       
   
   // Set a custom Persistent Store location
   [self configurePersistentStoreCoordinatorForURL:url ofType:NSSQLiteStoreType error:&error];              
   
   // Add some default scanning profiles   
   [self addDefaultProfiles];   
   
   // Load queued sessions in the persistent store into session manager
   [self addQueuedSessions];

   [notesDrawer open];
   [sessionsDrawer open];   
}

// -------------------------------------------------------------------------------
//	validateToolbarItem: 
// -------------------------------------------------------------------------------
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
   return YES;
}

static int numberOfShakes = 8;
static float durationOfShake = 0.5f;
static float vigourOfShake = 0.01f;
// Shaker, courtesy of http://www.cimgf.com/2008/02/27/core-animation-tutorial-window-shake-effect/
- (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame
{
   CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
	
   CGMutablePathRef shakePath = CGPathCreateMutable();
   CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
	int index;
	for (index = 0; index < numberOfShakes; ++index)
	{
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
	}
   CGPathCloseSubpath(shakePath);
   shakeAnimation.path = shakePath;
   shakeAnimation.duration = durationOfShake;
   return shakeAnimation;
}

- (IBAction)showProfileEditor:(id)sender
{
   if ([sender state] == 1)
   {
      [self switchToProfileEditor:nil];
   }
   else
   {
      [self switchToAdvanced:nil];
   }   
}

#pragma mark -
#pragma mark View switch handlers

// -------------------------------------------------------------------------------
//	segControlClicked: Delete/Play/Add segmented control in the lower-right
// -------------------------------------------------------------------------------
- (IBAction)segControlClicked:(id)sender
{
   switch ([sender selectedSegment]) {
      case 0:
         [self dequeueSession:self];
         break;
      case 1:
         [self processQueue:self];
         break;
      case 2:
         [self queueSession:self];
         break;         
      default:
         break;
   }
}

- (IBAction)modeSwitch2:(id)sender
{   
   switch ([sender selectedSegment]) {
      case 0:
         [self switchToBasic:nil];
         break;
      case 1:
         [self switchToAdvanced:nil];
         break;
      case 2:
         [self switchToAdvanced:nil];
         break;         
      default:
         break;
   }
}

- (IBAction)switchToBasic:(id)sender
{
   // Try to end editing
   NSWindow *w = [workspacePlaceholder window];
   BOOL ended = [w makeFirstResponder:w];
   if (!ended) {
      NSBeep();
      return;
   }
   
   [modeSwitchBar setSelectedSegment:0];
   
   BasicViewController *vc = [viewControllers objectAtIndex:0];
   
   NSView *workspaceBasicContent = [vc view];      
   NSView *targetBarBasicContent = [vc targetBarBasicContent];
   
   [targetBarBasicContent setFrame:[targetBarPlaceholder frame]];
   [[targetBarPlaceholder animator] replaceSubview:[[targetBarPlaceholder subviews] lastObject]   
                                              with:targetBarBasicContent];
   
   [workspaceBasicContent setFrame:[workspacePlaceholder frame]];
   [[workspacePlaceholder animator] replaceSubview:[[workspacePlaceholder subviews] lastObject]
                                              with:workspaceBasicContent];
   
}

- (IBAction)switchToAdvanced:(id)sender
{
   // Try to end editing
   NSWindow *w = [workspacePlaceholder window];
   BOOL ended = [w makeFirstResponder:w];
   if (!ended) {
      NSBeep();
      return;
   }
   
   [modeSwitchBar setSelectedSegment:1];
   
   AdvancedViewController *vc = [viewControllers objectAtIndex:1];

   // We have to refresh the console manually to prevent artifacts
   [[vc consoleOutputView] refreshWindow];
   
   NSView *workspaceAdvancedContent = [vc view];
   NSView *targetBarAdvancedContent = [vc targetBarAdvancedContent];
   
   [targetBarAdvancedContent setFrame:[targetBarPlaceholder frame]];
   [[targetBarPlaceholder animator] replaceSubview:[[targetBarPlaceholder subviews] lastObject]  
                                              with:targetBarAdvancedContent];
   [workspaceAdvancedContent setFrame:[workspacePlaceholder frame]];
   [[workspacePlaceholder animator] replaceSubview:[[workspacePlaceholder subviews] lastObject]
                                              with:workspaceAdvancedContent];
      
   [notesDrawer open];
   [sessionsDrawer open];
}

- (IBAction)switchToProfileEditor:(id)sender
{
   // Try to end editing
   NSWindow *w = [workspacePlaceholder window];
   BOOL ended = [w makeFirstResponder:w];
   if (!ended) {
      NSBeep();
      return;
   }
   
//   [modeSwitchBar setSelectedSegment:2];
   
   SettingsViewController *vc = [viewControllers objectAtIndex:2];      
   
   NSView *workspaceSettingsContent = [vc view];
//   NSView *targetBarSettingsContent = [vc targetBarSettingsContent];
   
//   [targetBarSettingsContent setFrame:[targetBarPlaceholder frame]];
//   [[targetBarPlaceholder animator] replaceSubview:[[targetBarPlaceholder subviews] lastObject] 
//                                              with:targetBarSettingsContent];
   
   [workspaceSettingsContent setFrame:[workspacePlaceholder bounds]];
   [[workspacePlaceholder animator] replaceSubview:[[workspacePlaceholder subviews] lastObject]
                                              with:workspaceSettingsContent];
      
}

#pragma mark -
#pragma mark Drawer methods

- (IBAction)toggleNotes:(id)sender
{
   // If we're zoomed in, toggle the internal view
   if ([mainWindow isZoomed] == YES)
   {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"BAFtoggleNotes" object:self];      
   }
   else
   {
      [notesDrawer toggle:sender];      
   }
}

- (IBAction) toggleSessions:(id)sender 
{
   // If we're zoomed in, toggle the internal view
   if ([mainWindow isZoomed] == YES)
   {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"BAFtoggleSessions" object:self];      
   }
   else
   {
      [sessionsDrawer toggle:self];    
   }
}


#pragma mark -
#pragma mark SessionManager methods
// -------------------------------------------------------------------------------
//	queueSession: Queue up a session using the currently selected Profile.
//
//   http://arstechnica.com/apple/guides/2009/04/cocoa-dev-the-joy-of-nspredicates-and-matching-strings.ars
// -------------------------------------------------------------------------------
- (IBAction)queueSession:(id)sender 
{   
   NSLog(@"MyDocument: queueSession");
   
   NSString *sessionTarget = nil;
   
   // We have to drill-down to find the proper TextField in the targetBarPlaceholder
//   if ( ([modeSwitchBar selectedSegment] == 1) || ([modeSwitchBar selectedSegment] == 2))
      sessionTarget = [[[[[targetBarPlaceholder subviews] lastObject] subviews] objectAtIndex:0] stringValue];
   
   NSLog(@"%@", [[[targetBarPlaceholder subviews] lastObject] subviews]);
   
   // Read the manual entry textfield, tokenize the string, and pull out
   //  arguments that start with '-', ie. nmap commands
   NSString *nmapCommand  = [nmapCommandTextField stringValue];
   NSArray *parsedNmapCommand = [nmapCommand componentsSeparatedByString:@" "];
   NSArray *nmapFlags = [parsedNmapCommand filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith '-'"]];
   
   // Check if the user entered any commands
   if ([nmapFlags count] == 0)
   {      
      // TODO: Check to make sure input arguments are valid
      [sessionManager queueSessionWithProfile:[[profilesArrayController selectedObjects] lastObject]
                                   withTarget:sessionTarget];      
      
   }
   // ... otherwise, parse the input commands and queue the session
   else
   {
      ArgumentListGenerator *a = [[ArgumentListGenerator alloc] init];   
      
      // Validate user-specified flags      
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
         [nmapCommandTextField setAnimations:[NSDictionary dictionaryWithObject:[self shakeAnimation:[nmapCommandTextField frame]] forKey:@"frameOrigin"]];
         [[nmapCommandTextField animator] setFrameOrigin:[nmapCommandTextField frame].origin];
      
//         nmapErrorCount = 1.0;
//         nmapErrorTimer = [[NSTimer scheduledTimerWithTimeInterval:0.07
//                                                   target:self
//                                                 selector:@selector(indicateEntryError:)
//                                                 userInfo:nil
//                                                  repeats:YES] retain]; 
      }

      // TODO: Why for thou crasheth?
      [a release];
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
   NSArray *array = [[self managedObjectContext] fetchObjectsForEntityName:@"Session" 
                                                             withPredicate:@"(status LIKE[c] 'Queued')"];                        
   
   if ([array count] > 0)
      [sessionManager queueExistingSessions:array];
   
   // This should probably be moved to it's own method, buuuuut...
   array = [[self managedObjectContext] fetchObjectsForEntityName:@"Session" withPredicate:
                     @"(status != 'Queued') AND (status != 'Done')"];   
   
   // Set incomplete scans to 'Aborted'
   if ([array count] > 0)
   {
      for (id object in array)
      {
         [object setStatus:@"Aborted"];
         [object setProgress:[NSNumber numberWithFloat:0.0]];
      }
   }   
}

#pragma mark -
#pragma mark Profiles drawer methods
// -------------------------------------------------------------------------------
//	addDefaultProfiles: 
// -------------------------------------------------------------------------------
- (void)addDefaultProfiles
{
   NSArray *array = [[self managedObjectContext] fetchObjectsForEntityName:@"Profile" withPredicate:nil];    
   
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

         // Add a few defaults         
         NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Default Profiles" ofType:@"plist"];                  
         NSArray *a = [NSArray arrayWithContentsOfFile:plistPath];
         
         Profile *profile = nil; 
         
         for (id defaultProfile in a)
         {
            profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
            [profile setValuesForKeysWithDictionary:defaultProfile];
            [profile setValue:profileParent forKey:@"parent"];            
         }
         
         // TODO: add --version-light
         // TODO: add --script-all
         
         // Add Saved Sessions parent folder
         profileParent = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
         [profileParent setValue: @"_Saved Sessions" forKey: @"name"]; 
         [profileParent setIsEnabled:NO];                  
      }
   }
}

#pragma mark Session Drawer Menu click-handlers

// -------------------------------------------------------------------------------
//	Session Drawer Menu click-handlers
// -------------------------------------------------------------------------------

- (Session *)clickedSessionInDrawer
{
   // Find clicked row from sessionsTableView
   NSInteger clickedRow = [sessionsTableView clickedRow];

   return [[sessionsArrayController arrangedObjects] objectAtIndex:clickedRow];
}

- (Session *)selectedSessionInDrawer
{
   // Find clicked row from sessionsTableView
   NSInteger selectedRow = [sessionsTableView selectedRow];

   return [[sessionsArrayController arrangedObjects] objectAtIndex:selectedRow];   
}

- (IBAction)sessionDrawerRun:(id)sender
{
   NSArray *selectedSessions = [sessionsArrayController selectedObjects];
   
   if ([selectedSessions count] > 1)
   {            
      for (id session in selectedSessions)
         [sessionManager launchSession:session];         
   }
   else 
   {
      [sessionManager launchSession:[selectedSessions lastObject]];
   }
}

- (IBAction)sessionDrawerRunCopy:(id)sender
{
   //ANSLog(@"MyDocument: sessionDrawerRunCopy - NOT IMPLEMENTED!");
}

- (IBAction) sessionDrawerAbort:(id)sender
{
   //ANSLog(@"MyDocument: Aborting session");
   
   NSArray *selectedSessions = [sessionsArrayController selectedObjects];
   
   if ([selectedSessions count] > 1)
   {      
      for (id session in selectedSessions)
         [sessionManager abortSession:session];         
   }
   else 
   {
      [sessionManager abortSession:[selectedSessions lastObject]];      
   }
}

- (IBAction) sessionDrawerRemove:(id)sender
{
   //ANSLog(@"MyDocument: Removing session");
   
   NSArray *selectedSessions = [sessionsArrayController selectedObjects];
   
   if ([selectedSessions count] > 1)
   {
      for (id session in selectedSessions)
         [sessionManager deleteSession:session];         
   }
   else 
   {
      [sessionManager deleteSession:[selectedSessions lastObject]];      
   }
}

- (IBAction) sessionDrawerShowInFinder:(id)sender
{   
   // Retrieve currently selected session
   NSString *savedSessionsDirectory = [prefsController reconSessionFolder];
   [[NSWorkspace sharedWorkspace] openFile:[savedSessionsDirectory stringByAppendingPathComponent:[[self clickedSessionInDrawer] UUID]]
                           withApplication:@"Finder"];

}

#pragma mark Table double-click handlers

// -------------------------------------------------------------------------------
//	Table click handlers
// -------------------------------------------------------------------------------

// Sessions Drawer click-handlers
- (void)sessionsTableDoubleClick
{
   //ANSLog(@"MyDocument: doubleClick!");
   
   // Retrieve currently selected session
   Session *selectedSession = [[sessionsArrayController selectedObjects] lastObject]; 
   
   if (selectedSession != nil) {
      // Retrieve currently selected profile
//      Profile *storedProfile = [selectedSession profile];
//      [profilesTreeController setContent:[NSArray arrayWithObject:storedProfile]];
      
      //   [[profilesTreeController selectedObjects] lastObject];
   }
}

#pragma mark -
#pragma mark Menu click-handlers

// -------------------------------------------------------------------------------
//	Main Menu key-handlers
// -------------------------------------------------------------------------------

// -------------------------------------------------------------------------------
//	Hands this functionality off to the PrefsController
// -------------------------------------------------------------------------------

- (IBAction)setuidNmap:(id)sender
{
   [prefsController rootNmap];
}
- (IBAction)unsetuidNmap:(id)sender
{
   [prefsController unrootNmap];
}
- (IBAction)showPrefWindow:(id)sender
{
   [prefsController showPrefWindow:self];
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
//      NSInteger clickedRow = [sessionsTableView clickedRow];
//      if (clickedRow == -1) {
      if ([[sessionsArrayController selectionIndexes] count] == 0) {
         enabled = NO;
      }
      else 
      {
         enabled = YES;
//         Session *s = [self clickedSessionInDrawer];
         
//         // Only enable Abort if session is running
//         if (
//             ([menuItem action] == @selector(sessionDrawerAbort:)) &&
//             ([s status] != @"Queued")
//            )         
//         {
//            //ANSLog(@"1");
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
   else if ([menuItem action] == @selector(handleHostsMenuClick:))
   {
//      if ([[hostsInSessionController selectedObjects] count] == 0)
////      if ([hostsTableView clickedRow] == -1)
//         enabled = NO;
//      else
//         enabled = YES;
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
//      Session *s = [self clickedSessionInDrawer];
//      if ([s status] == @"
   }
   else
   {
//   [sessionsContextMenu update];
   }
}


#pragma mark -
#pragma mark Notes methods

// TODO: This is duplicated in AdvancedViewController.  A boo...
- (IBAction)addNote:(id)sender
{
   //   [NSApp sendAction:@selector(addNote:) to:nil from:self];
   if ([mainWindow isZoomed] == NO)
   {
      HostNote *h = [notesInHostArrayController newObject];
      h.date = [NSDate date];
      h.name = @"New Note";
      [notesInHostArrayController addObject:h];
      [h release];
      
      // Re-sort (in case the user has sorted a column)
      [notesInHostArrayController rearrangeObjects];
      
      // Get the sorted array
      NSArray *a = [notesInHostArrayController arrangedObjects];
      
      // Find the object just added
      int row = [a indexOfObjectIdenticalTo:h];
      
      // Begin the edit in the first column
      [notesTableView editColumn:0
                             row:row
                       withEvent:nil
                          select:YES];   
   }
   else
   {
      AdvancedViewController *vc = [viewControllers objectAtIndex:1];
      [vc addNote:self];
   }
}


#pragma mark -
#pragma mark NSWindow hooks

- (IBAction)toggleFullScreen:(id)sender
{
   [mainWindow zoom:self];
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)proposedFrame
{
   if ([mainWindow isZoomed] == NO)
   {
      [sessionsDrawer close];
      [notesDrawer close];
      
      [mainWindow
       setFrame:[mainWindow frameRectForContentRect:[[mainWindow screen] frame]]
       display:YES
       animate:YES];      
      
      [self performSelector:@selector(zoomMainWindow) withObject:self afterDelay:0.2];
   }
   else
   {
      // Send notification to SessionManager that session is complete
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName:@"BAFmainWindowUnzoom" object:mainWindow];
      
      [self performSelector:@selector(unzoomMainWindow) withObject:self afterDelay:0.3];      
   }               
   
   return NO;
}

- (void)zoomMainWindow
{
   // Send notification to SessionManager that session is complete
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc postNotificationName:@"BAFmainWindowZoom" object:mainWindow];   
}

- (void)unzoomMainWindow
{    
   [mainWindow
    setFrame:[mainWindow frameRectForContentRect:standardWindowRect]
    display:YES
    animate:YES];
   
   [sessionsDrawer open];
   [notesDrawer open];         
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
   NSError *error;
   [[self managedObjectContext] save:&error];
}
- (IBAction)saveDocumentTo:(id)sender
{
   //ANSLog(@"SAVY?");
}
- (IBAction)saveDocumentAs:(id)sender
{
   //ANSLog(@"SAVY?");
}

// Overriding this allows us to create the illusion of Autosave
- (BOOL)isDocumentEdited
{
   return NO;
//   //ANSLog(@"EDIT!");
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

#pragma mark -
#pragma mark Dragging Destination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
   NSLog(@"draggingEntered:");
   if ([sender draggingSource] == self) {
      return NSDragOperationNone;
   }
   
//   highlighted = YES;
//   [self setNeedsDisplay:YES];
   return NSDragOperationCopy;
}
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
   //ANSLog(@"draggingExited:");
//   highlighted = NO;
//   [self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
   return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
   NSLog(@"S");
   NSPasteboard *pboard;
   NSDragOperation sourceDragMask;
   
   sourceDragMask = [sender draggingSourceOperationMask];
   pboard = [sender draggingPasteboard];
   NSLog(@"P");
   if ( [[pboard types] containsObject:NSFilenamesPboardType] ) 
   {      
   NSLog(@"Q");      
      NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];      

      for (NSString *i in files)
      {
         NSLog(@"performDragOperation: %@", i);
      }
//      // Depending on the dragging source and modifier keys,      
//      // the file data may be copied or linked      
//      if (sourceDragMask & NSDragOperationLink) {         
//         [self addLinkToFiles:files];         
//      } else {         
//         [self addDataFromFiles:files];         
//      }      
   }
   
   return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
   //ANSLog(@"concludeDragOperation:");
//   highlighted = NO;
//   [self setNeedsDisplay:YES];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{   
   NSLog(@"A");
   // Copy the row numbers to the pasteboard.
   
   //NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
//   NSData *data = [[NSString stringWithString:@"HELLO"] dataUsingEncoding:NSUTF8StringEncoding];
   
   [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
   
//   [pboard setData:data forType:NSStringPboardType];
   [pboard setString:@"JELLO" forType:NSStringPboardType];
   
   return YES;
   
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op

{
      NSLog(@"B");
   // Add code here to validate the drop
   
   //ANSLog(@"validate Drop");
   
   return NSDragOperationEvery;
   
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)sender

              row:(int)row dropOperation:(NSTableViewDropOperation)operation

{
//    NSLog(@"C");  
//   NSPasteboard* pboard = [info draggingPasteboard];
//   
//   NSData* rowData = [pboard dataForType:NSStringPboardType];
//   
//   NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
//   
////   int dragRow = [rowIndexes firstIndex];
//   
//   return TRUE;
   
   // Move the specified row to its new location...
   NSLog(@"S");
   NSPasteboard *pboard;
   NSDragOperation sourceDragMask;
   
   sourceDragMask = [sender draggingSourceOperationMask];
   pboard = [sender draggingPasteboard];
   NSLog(@"P");
   if ( [[pboard types] containsObject:NSFilenamesPboardType] ) 
   {      
      NSLog(@"Q");      
      NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];      
      
      for (NSString *i in files)
      {
         NSLog(@"performDragOperation: %@", i);
      }
      //      // Depending on the dragging source and modifier keys,      
      //      // the file data may be copied or linked      
      //      if (sourceDragMask & NSDragOperationLink) {         
      //         [self addLinkToFiles:files];         
      //      } else {         
      //         [self addDataFromFiles:files];         
      //      }      
   }
   
   return YES;
}


@end
