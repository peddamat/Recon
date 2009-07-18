//
//  DefaultsController.m
//  Recon
//
//  Created by Sumanth Peddamatham on 7/2/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "PrefsController.h"

NSString * const BAFNmapXRunOnce = @"NmapXRunOnce";
NSString * const BAFNmapBinLoc = @"NmapBinaryLocation";
NSString * const BAFSesSaveDir = @"SessionSaveDirectory";

@implementation PrefsController

+ (NSString *)applicationSupportFolder {
   
   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
   NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
   return [basePath stringByAppendingPathComponent:@"Recon"];
}

+ (NSString *)applicationSessionsFolder {
   
   return [[PrefsController applicationSupportFolder] stringByAppendingPathComponent:@"Sessions"];
}

// -------------------------------------------------------------------------------
//	registerDefaults: 
// -------------------------------------------------------------------------------
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
   [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
   [[NSUserDefaults standardUserDefaults] synchronize];
   
   NSLog(@"registered defaults: %@", defaultValues);    
}

// -------------------------------------------------------------------------------
//	checkPrefs: 
// -------------------------------------------------------------------------------
- (void)checkPrefs
{
   NSLog(@"checkPrefs!");
   
   // Verify nmap binary location points to valid nmap binary
   
   // Create application support directory, if needed
   NSFileManager *fileManager;
   NSString *applicationSupportFolder = nil;
   
   fileManager = [NSFileManager defaultManager];
   applicationSupportFolder = [PrefsController applicationSupportFolder];
   if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
      [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
   }

   // Create sessions folder, if needed
   NSString *applicationSessionsFolder = nil;
   
   fileManager = [NSFileManager defaultManager];
   applicationSessionsFolder = [PrefsController applicationSessionsFolder];
   if ( ![fileManager fileExistsAtPath:applicationSessionsFolder isDirectory:NULL] ) {
      [fileManager createDirectoryAtPath:applicationSessionsFolder attributes:nil];
   }
   
   // If log directory is valid, check for saved sessions
   
   // If there are saved sessions, load them into the sessions controller
}

// -------------------------------------------------------------------------------
//	rootNmap:
// -------------------------------------------------------------------------------
+ (BOOL)rootNmap
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
   char *myArguments[] = {"4777", "/usr/local/bin/nmap", NULL};
   FILE *myCommunicationsPipe = NULL;
   
   myFlags = kAuthorizationFlagDefaults;
   myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath, myFlags, myArguments, &myCommunicationsPipe);
   
   char *myToolPath2 = {"/usr/sbin/chown"};
   char *myArguments2[] = {"root", "/usr/local/bin/nmap", NULL};
   myCommunicationsPipe = NULL;
   
   myFlags = kAuthorizationFlagDefaults;
   myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath2, myFlags, myArguments2, &myCommunicationsPipe);
   
   NSLog(@"AuthHelperTool called AEWP");   
   return myStatus;
}

// -------------------------------------------------------------------------------
//	unrootNmap:
// -------------------------------------------------------------------------------
+ (BOOL)unrootNmap
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
   char *myArguments[] = {"770", "/usr/local/bin/nmap", NULL};
   FILE *myCommunicationsPipe = NULL;
   
   myFlags = kAuthorizationFlagDefaults;
   myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath, myFlags, myArguments, &myCommunicationsPipe);
   
   char *myToolPath2 = {"/usr/sbin/chown"};
   char *myArguments2[] = {"me:staff", "/usr/local/bin/nmap", NULL};
   myCommunicationsPipe = NULL;
   
   myFlags = kAuthorizationFlagDefaults;
   myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath2, myFlags, myArguments2, &myCommunicationsPipe);
   
   NSLog(@"AuthHelperTool called AEWP");   
   return myStatus;
}


- (NSString *) nmapBinary
{
   return [nmapBinaryString stringValue];
}

- (NSString *) logDirectory
{
   return [sessionDirectoryString stringValue];   
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

// Delegate method to handle saving user preferences on window close
//- (void)windowWillClose:(NSNotification *)notification
//{
//   NSLog(@"Window closing");
//}


@end
