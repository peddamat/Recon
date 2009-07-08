//
//  MyDocument.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright bafoontecha.com 2009 . All rights reserved.
//

#import "MyDocument.h"
#import "SessionController.h"

@class Profile;

NSString * const BAFNmapXRunOnce = @"NmapXRunOnce";
NSString * const BAFNmapBinLoc = @"NmapBinaryLocation";
NSString * const BAFSesSaveDir = @"SessionSaveDirectory";


//@interface SessionManager :NSObject
//{
//	NSMutableDictionary *runningSessionDictionary;
//   int sessionCount;
//}
//
//- (id)init
//{
//   runningSessionDictionary = [[NSMutableDictionary alloc] init];   
//   sessionCount = 0;
//}
//
//- (void)addSession:(Session *)session
//{
//   [runningSessionDictionary setObject:session forKey:[session sessionUUID]];   
//   
//}
//
//@end

@implementation SessionManager

@end

@implementation MyDocument

- (id)init 
{
    self = [super init];
    if (self != nil) {
        // initialization code
//       runningSessionDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)windowNibName 
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
}


/** Initialize UI defaults
 */
- (void)awakeFromNib
{
   
   NSLog(@"awakeFromNib!");
   
   [NSApp setServicesProvider:self];
   
   // Register user defaults
   [self registerDefaults];
   
   // If this is the first run, show Preferences window
   if ([self hasRun] == FALSE)
   {
      [self setRun];
      
      NSLog(@"Hasn't run");      
//      [self showPrefWindow:self];
   }
   
   // Use Preferences controller to verify nmap binary
   //   and log directory are set.
   PrefsController *prefs = [[PrefsController alloc] init];
   [prefs checkPrefs];
   
   // Open sessions drawer
   [sessionsDrawer toggle:self];   
   
   // Add some default profiles   
   [self addProfileDefaults];   
}

/** Start button handler
 */
- (IBAction)startButton:(id)sender 
{
   NSLog(@"MyDocument: startButton!");
   
   // TODO: Disable start button until ready to handle cancel event 
   
   // Retrieve currently selected profile
   NSArray *profiles = [profileController selectedObjects];
   Profile *profile = [profiles lastObject];
   
   // Switch main view to Results
//   [mainTabView selectTabViewItemAtIndex:1];
//   [self collapseProfileView];
   
   // TODO: Check to make sure input arguments are valid
   
   SessionController *currentSession = [[SessionController alloc] init];
   NSString *sessionUUID = [currentSession sessionUUID];
   
   // Store a pointer to the session in session Dictionary
   [runningSessionDictionary setObject:currentSession forKey:sessionUUID];
   
   // Register to receive notifications from SessionController
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self
          selector:@selector(sessionTerminated:)
              name:@"sessionTerminated"
            object:nil];
   NSLog(@"Registered with notification center");   
   
   // Initiate a new session
   [currentSession launchNewSessionWithProfile:profile withTarget:[sessionTarget stringValue] inManagedObjectContext:[self managedObjectContext]];
   
}

- (void)sessionTerminated: (NSNotification *)notification
{
   NSLog(@"MyDocument: Notification of session termination received!");
   
   // TODO: Remove completed session from Dictionary.  Notify user as needed.
}

- (void)addProfileDefaults
{
   NSManagedObjectContext * context = [self managedObjectContext]; 
   NSManagedObject * profile = nil; 
   profile = [NSEntityDescription insertNewObjectForEntityForName: @"Profile"  inManagedObjectContext: context]; 
   [profile setValue: @"Default" forKey: @"name"]; 
   NSLog (@"The Profile's name is: %@", [profile valueForKey:@"name"]);       
}

- (void)registerDefaults
{
   NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
   
   NSString *nmapBinaryLocation = @"/usr/local/bin/nmap";
   NSString *savedSessionsDirectory = [PrefsController applicationSessionsFolder];
   
   // Put defaults in the dictionary
   [defaultValues setObject:[NSNumber numberWithBool:NO]
                     forKey:BAFNmapXRunOnce];
   [defaultValues setObject:nmapBinaryLocation forKey:BAFNmapBinLoc];
   [defaultValues setObject:savedSessionsDirectory forKey:BAFSesSaveDir];
   
   // Register the dictionary of defaults
   [[NSUserDefaults standardUserDefaults]
    registerDefaults: defaultValues];
   
   [[NSUserDefaults standardUserDefaults] synchronize];
   
   NSLog(@"registered defaults: %@", defaultValues);    
}

- (void)updatePrefsWindow {
   NSString *nmapBinaryLocation = nil;
   NSString *savedSessionsDirectory = nil;
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   nmapBinaryLocation = (NSString *)[defaults objectForKey:BAFNmapBinLoc];    
   savedSessionsDirectory = (NSString *)[defaults objectForKey:BAFSesSaveDir];    

   [nmapBinaryString setStringValue:nmapBinaryLocation];
   [sessionDirectoryString setStringValue:savedSessionsDirectory];
}
- (BOOL)hasRun {
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   return [defaults boolForKey:BAFNmapXRunOnce];      
}
- (void)setRun {
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   [defaults setBool:1 forKey:BAFNmapXRunOnce];     
}


// Preference Window key-handlers
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
   
   [defaults setObject:nmapBinaryLocation forKey:BAFNmapBinLoc];
   [defaults setObject:savedSessionsDirectory forKey:BAFSesSaveDir];
      
   // Return to normal event handling
   [NSApp endSheet:prefWindow];
   
   // Hide the sheet
   [prefWindow orderOut:sender];
   
}

//  Profile SplitView key-handlers
- (void) collapseProfileView {
   if ([profileView collapsibleSubviewCollapsed] == FALSE)
      [profileView toggleCollapse:profileButton];      
}
- (void) expandProfileView {
   if ([profileView collapsibleSubviewCollapsed] == TRUE)
      [profileView toggleCollapse:profileButton];      
}
- (IBAction) toggleProfileView:(id)sender {
   [profileView toggleCollapse:profileButton];      
}

// Main Menu key-handlers
- (IBAction) toggleSettings:(id)sender {
   [mainTabView selectTabViewItemAtIndex:0];
}
- (IBAction) toggleResults:(id)sender {
   [mainTabView selectTabViewItemAtIndex:1];
}
- (IBAction) toggleSessionsDrawer:(id)sender {
   [sessionsDrawer toggle:self];    
}

// Session Drawer Menu key-handlers
- (IBAction) sessionDrawerRun:(id)sender
{
   NSLog(@"Click!");
}
- (IBAction) sessionDrawerRunCopy:(id)sender
{
   NSLog(@"Click!");
}
- (IBAction) sessionDrawerRemove:(id)sender
{
   NSLog(@"Click!");   
}
- (IBAction) sessionDrawerShowInFinder:(id)sender
{
   NSLog(@"Click!");   
}


// Handle context menu clicks
- (void)menuNeedsUpdate:(NSMenu *)menu 
{
   NSInteger clickedRow = [sessionsTableView clickedRow];
   NSInteger selectedRow = [sessionsTableView selectedRow];
   NSInteger numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   //(NSIndexSet *)selectedRowIndexes = [sessionsTableView selectedRowIndexes];
   
   // If clickedRow == -1, the user hasn't clicked on a session
   
   // TODO: If Sessions Context Menu
   if (menu == sessionsContextMenu) {
      NSLog(@"MyDocument: sessionsTableView clicked row: %i!", clickedRow);
      NSLog(@"MyDocument: sessionsTableView selected row: %i!", selectedRow);      
   }
   else
      NSLog(@"MyDocument: fart!");      
   
   // TODO: If Hosts Context Menu
   
   // TODO: If Ports in Host Context Menu
   
   // TODO: If Ports Context Menu
   
   // TODO: If Profiles Context Menu
   
   
}

/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
   
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
   
   return reply;
}

@end
