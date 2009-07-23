//
//  DefaultsController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/2/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "PrefsController.h"

NSString * const BAFReconHasRun = @"ReconHasRun";
NSString * const BAFNmapBinaryLocation = @"NmapBinaryLocation";
NSString * const BAFReconSupportDirectory = @"ReconSupportDirectory";

NSString * const BAFAutoSetuid = @"AutoSetuid";


@interface PrefsController ()

@property (readwrite, retain) NSString *nmapBinary;
@property (readwrite, retain) NSString *supportDirectory;
@property (readwrite, assign) BOOL setuidNmap;
@property (readwrite, assign) BOOL autoSetuid;

@end

// -------------------------------------------------------------------------------
//	THIS CLASS IS A SINGLETON.  
// -------------------------------------------------------------------------------

@implementation PrefsController

static PrefsController *sharedPrefsController = nil;

@synthesize nmapBinary;
@synthesize supportDirectory;
@synthesize setuidNmap;
@synthesize autoSetuid;

- (id)init
{
   if (self = [super init])
   {
      // The order that these occur matters...
      [self registerDefaults];
      [self readUserDefaults];
      [self checkPermsOnNmap];
      [self checkDirectories];
//      [self displayWelcomeWindow];      
   }
   
   return self;
}

- (void)awakeFromNib
{
}

// -------------------------------------------------------------------------------
//	registerDefaults: 
// -------------------------------------------------------------------------------
- (void)registerDefaults
{
   NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
   
   NSString *nmapBinaryLocation = @"/usr/local/bin/nmap";
   NSString *savedSessionsDirectory = [PrefsController applicationSupportFolder];
   
   // Put defaults in the dictionary
   [defaultValues setObject:[NSNumber numberWithBool:NO]
                     forKey:BAFReconHasRun];
   [defaultValues setObject:[NSNumber numberWithBool:NO]
                     forKey:BAFAutoSetuid];

   [defaultValues setObject:nmapBinaryLocation 
                     forKey:BAFNmapBinaryLocation];
   [defaultValues setObject:savedSessionsDirectory
                     forKey:BAFReconSupportDirectory];
   
   // Register the dictionary of defaults
   [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
   [[NSUserDefaults standardUserDefaults] synchronize];
   
   NSLog(@"PrefsController: Registered defaults");
}

// -------------------------------------------------------------------------------
//	readUserDefaults:
// -------------------------------------------------------------------------------
- (void)readUserDefaults 
{   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   self.autoSetuid = [defaults boolForKey:BAFAutoSetuid]; 
   self.nmapBinary = (NSString *)[defaults objectForKey:BAFNmapBinaryLocation]; 
   self.supportDirectory = (NSString *)[defaults objectForKey:BAFReconSupportDirectory];   
}

// -------------------------------------------------------------------------------
//	checkPermsOnNmap: The checkbox in the UI is bound to the setuidNmap instance
//                   variable.  Update the checkbox to reflect the perms of Nmap.
// -------------------------------------------------------------------------------
- (void)checkPermsOnNmap
{
   // Check file permissions
   NSFileManager *fm = [NSFileManager defaultManager];
   NSError *error = nil;
   NSDictionary *d = [fm attributesOfItemAtPath:nmapBinary error:&error];
   
   NSNumber *s = [d valueForKey:NSFilePosixPermissions];
   NSNumber *p = [d valueForKey:NSFileOwnerAccountID];
   
   // If the file doesn't have the right permissions, unset the checkbox
   if (([s unsignedLongValue] != 2559) || ([p unsignedLongValue] != 0))
   {
      self.setuidNmap = NO;
   }
   else
   {
      self.setuidNmap = YES;
   }   
}

// -------------------------------------------------------------------------------
//	checkDirectories: 
// -------------------------------------------------------------------------------
- (void)checkDirectories
{   
   // Create application support directory, if needed
   NSFileManager *fileManager = [NSFileManager defaultManager];
   NSString *applicationSupportFolder = [self reconSupportFolder];   
   
   if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
      [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
   }
   
   // Create sessions folder, if needed
   NSString *applicationSessionsFolder = nil;
   
   applicationSessionsFolder = [self reconSessionFolder];      
   if ( ![fileManager fileExistsAtPath:applicationSessionsFolder isDirectory:NULL] ) {
      [fileManager createDirectoryAtPath:applicationSessionsFolder attributes:nil];
   }
   
   NSLog(@"PrefsController: checkDirectories!");   
}

// -------------------------------------------------------------------------------
//	displayWelcomeWindow: Displays the preference window the first time Recon is executed.
// -------------------------------------------------------------------------------
- (void)displayWelcomeWindow
{
   if ([self hasReconRunBefore] == NO) {
      // Hack to prevent detached sheet
      //  See: http://www.cocoadev.com/index.pl?HowToPutASheetOnADocumentJustAfterOpeningIt
      [self performSelector:@selector(showFirstRunWindow:) withObject:self afterDelay:0.5];
   }      
}

- (IBAction)showFirstRunWindow:(id)sender {   
   
   // Then display as sheet
   [NSApp beginSheet:firstRunWindow
      modalForWindow:mainWindow
       modalDelegate:self
      didEndSelector:NULL
         contextInfo:NULL];   
}

- (IBAction)endFirstRunWindow:(id)sender {
   
   // Verify user-specified settings are valid
   
   // Then store them to User Defaults 
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
   [defaults setBool:autoSetuid forKey:BAFAutoSetuid];
   [defaults setObject:nmapBinary forKey:BAFNmapBinaryLocation];
   [defaults setObject:supportDirectory forKey:BAFReconSupportDirectory];
   
   [self setRun];
   
   // Return to normal event handling
   [NSApp endSheet:firstRunWindow];
   
   // Hide the sheet
   [firstRunWindow orderOut:sender];
   
   // Notify everyone that the Prefs have been updated
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];      
   [nc postNotificationName:@"BAFupdateSupportFolder" object:self];  
   [nc postNotificationName:@"BAFfinishFirstRun" object:self];
}

// -------------------------------------------------------------------------------
//	Preference Window key-handlers
// -------------------------------------------------------------------------------

- (IBAction)showPrefWindow:(id)sender {   
      
   // Then display as sheet
   [NSApp beginSheet:prefWindow
      modalForWindow:mainWindow
       modalDelegate:self
      didEndSelector:NULL
         contextInfo:NULL];   
}

- (IBAction)endPrefWindow:(id)sender {
   
   // Verify user-specified settings are valid
   
   // Then store them to User Defaults 
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
   [defaults setBool:autoSetuid forKey:BAFAutoSetuid];
   [defaults setObject:nmapBinary forKey:BAFNmapBinaryLocation];
   [defaults setObject:supportDirectory forKey:BAFReconSupportDirectory];
   
   [self setRun];
   
   // Return to normal event handling
   [NSApp endSheet:prefWindow];
   
   // Hide the sheet
   [prefWindow orderOut:sender];
   
   // Notify everyone that the Prefs have been updated
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];      
   [nc postNotificationName:@"BAFupdateSupportFolder" object:self];  
}

// -------------------------------------------------------------------------------
//	browseNmapBinary: TODO: refactor these functions!
// -------------------------------------------------------------------------------
- (IBAction)browseNmapBinary:(id)sender
{   
   // Create the File Open Dialog class.
   NSOpenPanel* openDlg = [NSOpenPanel openPanel];
   
   // Enable the selection of files in the dialog.
   [openDlg setCanChooseFiles:YES];
   
   // Enable the selection of directories in the dialog.
   [openDlg setCanChooseDirectories:NO];
   
   // Display the dialog.  If the OK button was pressed,
   // process the files.
   if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
   {
      // Get an array containing the full filenames of all
      // files and directories selected.
      NSArray* files = [openDlg filenames];
      
      // Loop through all the files and process them.
      for(int i = 0; i < [files count]; i++ )
      {
         NSString* fileName = [files objectAtIndex:i];

         self.nmapBinary = fileName;            // Save new binary location
         [self checkPermsOnNmap];               // Check file permissions
         [nmapBinaryTextField selectText:self]; // Friendlify GUI
      }
   }
}

// -------------------------------------------------------------------------------
//	browseSupportDirectory: TODO: refactor these functions!
// -------------------------------------------------------------------------------
- (IBAction)browseSupportDirectory:(id)sender
{
   // Create the File Open Dialog class.
   NSOpenPanel* openDlg = [NSOpenPanel openPanel];
   
   // Enable the selection of files in the dialog.
   [openDlg setCanChooseFiles:NO];
   
   // Enable the selection of directories in the dialog.
   [openDlg setCanChooseDirectories:YES];
   
   // Display the dialog.  If the OK button was pressed,
   // process the files.
   if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
   {
      // Get an array containing the full filenames of all
      // files and directories selected.
      NSArray* files = [openDlg filenames];
      
      // Loop through all the files and process them.
      for(int i = 0; i < [files count]; i++ )
      {
         NSString* fileName = [files objectAtIndex:i];
         
         self.supportDirectory = fileName;            // Save the new directory
         [self checkDirectories];                     // Create subdirectories
         [supportDirectoryTextField selectText:self]; // Friendlify GUI
      }
   }
}

// -------------------------------------------------------------------------------
//	toggleNmapPerms:
// -------------------------------------------------------------------------------
- (IBAction)toggleNmapPerms:(id)sender
{
   // If the binary doesn't have root...
   if (self.setuidNmap == YES)
   {
      // Root it
      [self rootNmap];
      [self checkPermsOnNmap];
   }
   // Otherwise, unroot it...
   else
   {
      [self unrootNmap];
      [self checkPermsOnNmap];
   }
}

// -------------------------------------------------------------------------------
//	rootNmap:
// -------------------------------------------------------------------------------
- (BOOL)rootNmap
{
   // Paraphrased from http://developer.apple.com/documentation/Security/Conceptual/authorization_concepts/03authtasks/chapter_3_section_4.html
   OSStatus myStatus;
   AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
   AuthorizationRef myAuthorizationRef;
   
   myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
   if (myStatus != errAuthorizationSuccess)
      return myStatus;
   
   AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
   AuthorizationRights myRights = {1, &myItems};
   myFlags = kAuthorizationFlagDefaults |
   kAuthorizationFlagInteractionAllowed |
   kAuthorizationFlagPreAuthorize |
   kAuthorizationFlagExtendRights;
   
   myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, NULL, myFlags, NULL );
   if (myStatus != errAuthorizationSuccess)
      return myStatus;
   
   char *myToolPath = {"/bin/chmod"};
   const char *myBinaryPath = [nmapBinary cStringUsingEncoding:NSUTF8StringEncoding];
   char *myArguments[] = {"4777", myBinaryPath, NULL};   
   FILE *myCommunicationsPipe = NULL;
   
   myFlags = kAuthorizationFlagDefaults;
   myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath, myFlags, myArguments, &myCommunicationsPipe);
   
   char *myToolPath2 = {"/usr/sbin/chown"};
   const char *myBinaryPath2 = [nmapBinary cStringUsingEncoding:NSUTF8StringEncoding];   
   char *myArguments2[] = {"root", myBinaryPath2, NULL};   
   myCommunicationsPipe = NULL;
   
   myFlags = kAuthorizationFlagDefaults;
   myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath2, myFlags, myArguments2, &myCommunicationsPipe);
   
   NSLog(@"AuthHelperTool called AEWP");   
   return myStatus;
}

// -------------------------------------------------------------------------------
//	unrootNmap:
// -------------------------------------------------------------------------------
- (BOOL)unrootNmap
{
   // Paraphrased from http://developer.apple.com/documentation/Security/Conceptual/authorization_concepts/03authtasks/chapter_3_section_4.html
   OSStatus myStatus;
   AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
   AuthorizationRef myAuthorizationRef;
   
   myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
   if (myStatus != errAuthorizationSuccess)
      return myStatus;
   
   AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
   AuthorizationRights myRights = {1, &myItems};
   myFlags = kAuthorizationFlagDefaults |
   kAuthorizationFlagInteractionAllowed |
   kAuthorizationFlagPreAuthorize |
   kAuthorizationFlagExtendRights;
   
   myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, NULL, myFlags, NULL );
   if (myStatus != errAuthorizationSuccess)
      return myStatus;
   
   char *myToolPath = {"/bin/chmod"};
   const char *myBinaryPath = [nmapBinary cStringUsingEncoding:NSUTF8StringEncoding];      
   char *myArguments[] = {"770", myBinaryPath, NULL};
   FILE *myCommunicationsPipe = NULL;
   
   myFlags = kAuthorizationFlagDefaults;
   myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath, myFlags, myArguments, &myCommunicationsPipe);
   
   char *myToolPath2 = {"/usr/sbin/chown"};
   const char *myBinaryPath2 = [nmapBinary cStringUsingEncoding:NSUTF8StringEncoding];   
   char *myArguments2[] = {"me:staff", myBinaryPath2, NULL};   
   myCommunicationsPipe = NULL;
   
   myFlags = kAuthorizationFlagDefaults;
   myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath2, myFlags, myArguments2, &myCommunicationsPipe);
   
   NSLog(@"AuthHelperTool called AEWP");   
   return myStatus;
}

// -------------------------------------------------------------------------------
//	applicationSupportFolder: Return the system-wide application support folder
// -------------------------------------------------------------------------------
+ (NSString *)applicationSupportFolder {
   
   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
   NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
   return [basePath stringByAppendingPathComponent:@"Recon"];
}

// -------------------------------------------------------------------------------
//	applicationSessionsFolder: Sessions are stored in a sub-folder of the main support folder
// -------------------------------------------------------------------------------
+ (NSString *)applicationSessionsFolder {
   
   return [[PrefsController applicationSupportFolder] stringByAppendingPathComponent:@"Sessions"];
}

- (NSString *)reconSupportFolder {
   return self.supportDirectory;
}

- (NSString *)reconSessionFolder {
   return [supportDirectory stringByAppendingPathComponent:@"Sessions"];
}

// -------------------------------------------------------------------------------
//	hasReconRunBefore: Has Recon executed on this machine?
// -------------------------------------------------------------------------------
- (BOOL)hasReconRunBefore {
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   return [defaults boolForKey:BAFReconHasRun];      
}

// -------------------------------------------------------------------------------
//	setRun: Dirty has run flag
// -------------------------------------------------------------------------------
- (void)setRun {
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   [defaults setBool:1 forKey:BAFReconHasRun];     
}

// Delegate method to handle saving user preferences on window close
//- (void)windowWillClose:(NSNotification *)notification
//{
//   NSLog(@"Window closing");
//}

// -------------------------------------------------------------------------------
//	The following methods allow this class to be a Singleton.
//
//  They are adapted from:
//    http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html
// -------------------------------------------------------------------------------

+ (PrefsController *)sharedPrefsController
{
   @synchronized(self) {
      if (sharedPrefsController == nil) {         
         [[self alloc] init]; // assignment not done here         
      }      
   }
   
   return sharedPrefsController;   
}

+ (id)allocWithZone:(NSZone *)zone
{
   @synchronized(self) {
      if (sharedPrefsController == nil) {
         sharedPrefsController = [super allocWithZone:zone];
         return sharedPrefsController;  // assignment and return on first allocation
      }
   }
   return nil; //on subsequent allocation attempts return nil   
}

- (id)copyWithZone:(NSZone *)zone
{
   return self;   
}

- (id)retain
{
   
   return self;   
}

- (unsigned)retainCount
{   
   return UINT_MAX;  //denotes an object that cannot be released   
}

- (void)release
{
   //do nothing   
}

- (id)autorelease

{
   return self;
}


@end
