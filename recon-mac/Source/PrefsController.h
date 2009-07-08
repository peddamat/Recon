//
//  DefaultsController.h
//  nmapX-coredata
//
//  Created by Sumanth Peddamatham on 7/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
//  Handles User Preferences window.


#import <Cocoa/Cocoa.h>

@interface PrefsController : NSObject {

   IBOutlet NSTextField *nmapBinaryString;   
   IBOutlet NSTextField *sessionDirectoryString;
   IBOutlet NSWindow *myWindow;
}

// Add methods to retrieve nmap binary
//   and log directory

- (void) checkPrefs;
- (void) checkFirstRun;
+ (NSString *) nmapBinary;
+ (NSString *) logDirectory;

+ (NSString *)applicationSessionsFolder;
+ (NSString *)applicationSupportFolder;

@end
