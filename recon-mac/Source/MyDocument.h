//
//  MyDocument.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright bafoontecha.com 2009 . All rights reserved.
//
//  http://www.cocoadevcentral.com/articles/000086.php

#import <Cocoa/Cocoa.h>
#import "PrefsController.h"
#import <BWToolkitFramework/BWSplitView.h>
#import <BWToolkitFramework/BWAnchoredButton.h>

// User application default keys
extern NSString * const BAFNmapXRunOnce;
extern NSString * const BAFNmapBinaryLocation;
extern NSString * const BAFSessionSaveDirectory;

@interface MyDocument : NSPersistentDocument {
   
   IBOutlet NSView *mainView;

   // Session Drawer outlets
   IBOutlet NSDrawer *sessionsDrawer;
   IBOutlet NSTableView *sessionsTableView;
   IBOutlet NSMenu *sessionsContextMenu;
   
   IBOutlet NSButton *startButton;
   IBOutlet NSArrayController *profileController;   
   IBOutlet NSTextField *sessionTarget;
   IBOutlet NSTabView *mainTabView;
   
   IBOutlet NSWindow *prefWindow;
   IBOutlet NSTextField *nmapBinaryString;   
   IBOutlet NSTextField *sessionDirectoryString;   
   IBOutlet NSButton *nmapBinaryBrowse;
   IBOutlet NSButton *logDirectoryBrowse;
   
   IBOutlet BWSplitView *profileView;
   IBOutlet BWAnchoredButton *profileButton;
   
   // Main Menu outlets
   IBOutlet NSMenuItem *menuSettings;
   IBOutlet NSMenuItem *menuResults;   
      
   NSMutableDictionary *runningSessionDictionary;
   
}

// Sessions Drawer click-handlers
- (IBAction) sessionDrawerRun:(id)sender;
- (IBAction) sessionDrawerRunCopy:(id)sender;
- (IBAction) sessionDrawerRemove:(id)sender;
- (IBAction) sessionDrawerShowInFinder:(id)sender;

- (IBAction) startButton:(id)sender;

- (IBAction) toggleSettings:(id)sender;
- (IBAction) toggleResults:(id)sender;

- (IBAction) showPrefWindow:(id)sender;
- (IBAction) endPrefWindow:(id)sender;

- (IBAction) toggleSessionsDrawer:(id)sender;

- (void) expandProfileView;
- (void) collapseProfileView;
- (IBAction) toggleProfileView:(id)sender;

- (void)registerDefaults;
- (void)updatePrefsWindow;
- (BOOL)hasRun;
- (void)setRun;

@end
