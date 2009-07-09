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

#import "ExpertSettingsViewController.h"
#import "ExpertResultsViewController.h"

#import "Session.h"

@class Profile;

NSString * const BAFNmapXRunOnce = @"NmapXRunOnce";
NSString * const BAFNmapBinLoc = @"NmapBinaryLocation";
NSString * const BAFSesSaveDir = @"SessionSaveDirectory";


@implementation MyDocument

- (id)init 
{
    if (self = [super init])
    {
       sessionManager = [[SessionManager alloc] init];
       
       viewControllers = [[NSMutableArray alloc] init];
       
       ManagingViewController *vc;
       vc = [[ExpertSettingsViewController alloc] init];
       [vc setManagedObjectContext:[self managedObjectContext]];
       [viewControllers addObject:vc];
       [vc release];
       
       vc = [[ExpertResultsViewController alloc] init];
       [vc setManagedObjectContext:[self managedObjectContext]];
       [viewControllers addObject:vc];
       [vc release];       
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
   if ([self hasRun] == FALSE) {
      [self setRun];      
      NSLog(@"Hasn't run");      
   }
   
   // Setup initial view
   [self displayViewController:0];
   
   // Use Preferences controller to verify nmap binary and log directory are set.
   PrefsController *prefs = [[PrefsController alloc] init];
   [prefs checkPrefs];
   [prefs release];
   
   // Open sessions drawer
   [sessionsDrawer toggle:self];   
   
   // Add some default profiles   
   [self addProfileDefaults];   
   
   [sessionsTableView setTarget:self];
   [sessionsTableView setDoubleAction:@selector(sessionsTableDoubleClick)];
   
   [hostsTableView setTarget:self];
   [hostsTableView setDoubleAction:@selector(hostsTableDoubleClick)];
}


/** Start button handler
 */
- (IBAction)queueSession:(id)sender 
{   
   // Retrieve currently selected profile
   Profile *profile = [[profileController selectedObjects] lastObject];
      
   // TODO: Check to make sure input arguments are valid
   [sessionManager queueSessionWithProfile:profile andTarget:[sessionTarget stringValue]];
}

- (IBAction)processQueue:(id)sender
{
   NSLog(@"MyDocument: processSessions!");
   
   [sessionManager processQueue];
}

- (void)addProfileDefaults
{
   NSManagedObjectContext * context = [self managedObjectContext]; 
   NSManagedObject *profile = nil; 
   profile = [NSEntityDescription insertNewObjectForEntityForName:@"Profile" inManagedObjectContext:context]; 
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

- (void) displayViewController:(int)i
{
   ManagingViewController *vc = [viewControllers objectAtIndex:i];
   NSWindow *w = [mainBox window];
   BOOL ended = [w makeFirstResponder:w];
   if (!ended) {
      NSBeep();
      return;
   }
   // Put the view in the box
   [mainBox setContentView:[vc view]]; 
}

// Main Menu key-handlers
- (IBAction) toggleSettings:(id)sender {
   [self displayViewController:0];
}
- (IBAction) toggleResults:(id)sender {
   [self displayViewController:1];
}
- (IBAction) toggleSessionsDrawer:(id)sender {
   [sessionsDrawer toggle:self];    
}

- (NSString *)clickedUUID
{
   // Find clicked row from sessionsTableView
   NSInteger clickedRow = [sessionsTableView clickedRow];
   // Get selected object from sessionsController 
   return [[[sessionsController arrangedObjects] objectAtIndex:clickedRow] UUID];
   
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
   // Retrieve currently selected session
//   Session *selectedSession = [[sessionsController selectedObjects] lastObject]; 

//   [[NSWorkspace sharedWorkspace] openFile:[savedSessionsDirectory stringByAppendingPathComponent:[selectedSession UUID]]
//                           withApplication:@"Finder"];

   NSString *savedSessionsDirectory = [PrefsController applicationSessionsFolder];     
   [[NSWorkspace sharedWorkspace] openFile:[savedSessionsDirectory stringByAppendingPathComponent:[self clickedUUID]]
                           withApplication:@"Finder"];

}


- (void)hostsTableDoubleClick
{
   [self toggleResults:self];
}

/// Sessions Drawer click-handlers

- (void)sessionsTableDoubleClick
{
   NSLog(@"MyDocument: doubleClick!");
   
   // Retrieve currently selected session
   Session *selectedSession = [[sessionsController selectedObjects] lastObject];   
   // Retrieve currently selected profile
   Profile *storedProfile = [selectedSession profile];
   [profileController setSelectedObjects:[NSArray arrayWithObject:storedProfile]];
   
   //   [[profileController selectedObjects] lastObject];
   
}

// Handle context menu clicks in Sessions TableView
- (void)menuNeedsUpdate:(NSMenu *)menu 
{
   NSInteger clickedRow = [sessionsTableView clickedRow];
   NSInteger selectedRow = [sessionsTableView selectedRow];
   NSInteger numberOfSelectedRows = [sessionsTableView numberOfSelectedRows];
   //(NSIndexSet *)selectedRowIndexes = [sessionsTableView selectedRowIndexes];
   
   // If clickedRow == -1, the user hasn't clicked on a session
   
   // TODO: If Sessions Context Menu
   if (menu == sessionsContextMenu) {
      NSArray *menuItems = [menu itemArray];
      NSMenuItem *menuItem = nil;
      
      // First iterate through boolean arguments
      NSEnumerator *e = [menuItems objectEnumerator];
      
      while ( menuItem = [e nextObject] )
      {
         [menuItem setEnabled:FALSE];
      }
         
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

- (void)dealloc
{
   [viewControllers release];
   [super dealloc];
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
