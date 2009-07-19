//
//  DefaultsController.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/2/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//
//  Handles User Preferences window.


#import <Cocoa/Cocoa.h>

@interface PrefsController : NSWindowController {

   IBOutlet NSWindow *mainWindow;
   IBOutlet NSWindow *prefWindow;
   
   IBOutlet NSButton *setuidNmapButton;
   IBOutlet NSButton *autoSetuidButton;
   
   IBOutlet NSTextField *nmapBinaryTextField;   
   IBOutlet NSTextField *sessionDirectoryTextField;
   
   NSString *nmapBinary; 
   NSString *sessionDirectory;
   
   BOOL setuidNmap;
   BOOL autoSetuid;
}

@property (readonly,retain) NSString *nmapBinary;
@property (readonly,retain) NSString *sessionDirectory;

+ (PrefsController *)sharedPrefsController;

- (void)displayOnFirstRun;

+ (NSString *)applicationSessionsFolder;
+ (NSString *)applicationSupportFolder;

- (void)registerDefaults;
- (void)checkPrefs;

- (IBAction)showPrefWindow:(id)sender;
- (IBAction)endPrefWindow:(id)sender;
- (void)readUserDefaults;

// Nmap set/desetuid functions
+ (BOOL)rootNmap;
+ (BOOL)unrootNmap;

+ (NSString *)nmapBinary;
+ (NSString *)logDirectory;

- (BOOL)hasRun;
- (void)setRun;

// Add methods to retrieve nmap binary
//   and log directory

- (void) checkPrefs;

- (IBAction)browseNmapBinary:(id)sender;
- (IBAction)browseSessionDirectory:(id)sender;

- (IBAction)toggleNmapPerms:(id)sender;
- (void)checkPermsOnNmap;

@end
