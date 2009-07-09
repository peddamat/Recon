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

@class SessionManager;

// User application default keys
extern NSString * const BAFNmapXRunOnce;
extern NSString * const BAFNmapBinaryLocation;
extern NSString * const BAFSessionSaveDirectory;

@interface MyDocument : NSPersistentDocument {
   
   SessionManager *sessionManager;
   NSMutableArray *viewControllers;
   IBOutlet NSBox *mainBox;
   
   IBOutlet NSView *mainView;

   // Session Drawer
   IBOutlet NSDrawer *sessionsDrawer;
   IBOutlet NSTableView *sessionsTableView;
   IBOutlet NSMenu *sessionsContextMenu;
   IBOutlet NSArrayController *sessionsController;
   
   IBOutlet NSButton *startButton;
   IBOutlet NSArrayController *profileController;   
   IBOutlet NSTextField *sessionTarget;
   IBOutlet NSTabView *mainTabView;
   
   // Preference Window
   IBOutlet NSWindow *prefWindow;
   IBOutlet NSTextField *nmapBinaryString;   
   IBOutlet NSTextField *sessionDirectoryString;   
   IBOutlet NSButton *nmapBinaryBrowse;
   IBOutlet NSButton *logDirectoryBrowse;
   
   IBOutlet BWSplitView *profileView;
   IBOutlet BWAnchoredButton *profileButton;

   IBOutlet NSTableView *hostsTableView;
   
   // Main Menu 
   IBOutlet NSMenuItem *menuSettings;
   IBOutlet NSMenuItem *menuResults;   
   
}

- (void) displayViewController:(int)i;

// Sessions Drawer click-handlers
- (IBAction) sessionDrawerRun:(id)sender;
- (IBAction) sessionDrawerRunCopy:(id)sender;
- (IBAction) sessionDrawerRemove:(id)sender;
- (IBAction) sessionDrawerShowInFinder:(id)sender;

// Session Manager click-handlers
- (IBAction) queueSession:(id)sender;
- (IBAction) processQueue:(id)sender;

- (IBAction) toggleSettings:(id)sender;
- (IBAction) toggleResults:(id)sender;

- (IBAction) showPrefWindow:(id)sender;
- (IBAction) endPrefWindow:(id)sender;

- (IBAction) toggleSessionsDrawer:(id)sender;

- (void) expandProfileView;
- (void) collapseProfileView;
- (IBAction) toggleProfileView:(id)sender;

- (void)addProfileDefaults;
- (void)registerDefaults;
- (void)updatePrefsWindow;
- (BOOL)hasRun;
- (void)setRun;


@end
