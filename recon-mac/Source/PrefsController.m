//
//  DefaultsController.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/2/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "PrefsController.h"


@implementation PrefsController

/**
 Returns the support folder for the application, used to store the Core Data
 store file.  This code uses a folder named "Molecular_Core" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

+ (NSString *)applicationSupportFolder {
   
   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
   NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
   return [basePath stringByAppendingPathComponent:@"recon"];
}

+ (NSString *)applicationSessionsFolder {
   
   return [[PrefsController applicationSupportFolder] stringByAppendingPathComponent:@"Sessions"];
}

// Delegate method to handle saving user preferences on window close
- (void)windowWillClose:(NSNotification *)notification
{
   NSLog(@"Window closing");
}

- (void) checkPrefs
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

- (NSString *) nmapBinary
{
   return [nmapBinaryString stringValue];
}

- (NSString *) logDirectory
{
   return [sessionDirectoryString stringValue];   
}


@end
