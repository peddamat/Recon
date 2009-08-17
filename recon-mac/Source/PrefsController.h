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
   IBOutlet NSWindow *firstRunWindow;
   
   IBOutlet NSButton *setuidNmapButton;
   IBOutlet NSButton *autoSetuidButton;
   
   IBOutlet NSTextField *nmapBinaryTextField;   
   IBOutlet NSTextField *supportDirectoryTextField;
   
   NSString *nmapBinary; 
   NSString *supportDirectory;
   
   BOOL setuidNmap;
   BOOL autoSetuid;
}

@property (readonly,retain) NSString *nmapBinary;
@property (readonly,retain) NSString *supportDirectory;

+ (PrefsController *)sharedPrefsController;

- (void)displayWelcomeWindow;

+ (NSString *)applicationSupportFolder;
+ (NSString *)applicationSessionsFolder;

- (NSString *)reconSupportFolder;
- (NSString *)reconSessionFolder;

- (void)registerDefaults;
- (void)readUserDefaults;
- (void)checkDirectories;
- (void)checkPermsOnNmap;
- (void)checkDirectories;

- (IBAction)showPrefWindow:(id)sender;
- (IBAction)endPrefWindow:(id)sender;
- (IBAction)endFirstRunWindow:(id)sender;

// Nmap set/desetuid functions
- (BOOL)rootNmap;
- (BOOL)unrootNmap;
- (IBAction)toggleNmapPerms:(id)sender;

- (BOOL)hasReconRunBefore;
- (void)setRun;

- (IBAction)browseNmapBinary:(id)sender;
- (IBAction)browseSupportDirectory:(id)sender;

@end
