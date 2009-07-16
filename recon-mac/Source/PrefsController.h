//
//  DefaultsController.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/2/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
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

// Nmap set/desetuid functions
- (BOOL)rootNmap;
- (BOOL)unrootNmap;

+ (NSString *)applicationSessionsFolder;
+ (NSString *)applicationSupportFolder;

@end
