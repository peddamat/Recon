//
//  MyDocument.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/1/09.
//  Copyright bafoontecha.com 2009 . All rights reserved.
//
//  http://www.cocoadevcentral.com/articles/000086.php

#import <Cocoa/Cocoa.h>
#import "PrefsController.h"
#import <BWToolkitFramework/BWSplitView.h>
#import <BWToolkitFramework/BWAnchoredButton.h>

@class Session;
@class SessionManager;
@class PrefsController;

// User application default keys
extern NSString * const BAFReconHasRun;
extern NSString * const BAFNmapBinaryLocation;
extern NSString * const BAFSavedSessionsDirectory;

@interface MyDocument : NSPersistentDocument {
   
   IBOutlet NSView *mainView;
   IBOutlet NSView *mainsubView;   
   IBOutlet NSTabView *mainTabView;

   PrefsController *prefsController;
   SessionManager *sessionManager;
   
   // Toolbar Outlets
   IBOutlet NSToolbar *mainToolbar;
   IBOutlet NSToolbarItem *settingsToolbarItem;
   IBOutlet NSToolbarItem *resultsToolbarItem;  
   
   // Queue Controls
   IBOutlet NSSegmentedControl *queueSegmentedControl;
   
   // Network Interface Popup
   IBOutlet NSPopUpButton *interfacesPopUp;
   NSMutableDictionary *interfacesDictionary;  
   
   // TCP/Non-TCP/Timings Popup
   IBOutlet NSPopUpButton *tcpScanPopUp;
   IBOutlet NSPopUpButton *nonTcpScanPopUp;
   IBOutlet NSPopUpButton *timingTemplatePopUp;   
      
   // Session Drawer
   IBOutlet NSDrawer *sessionsDrawer;
   IBOutlet NSTableView *sessionsTableView;
   IBOutlet NSMenu *sessionsContextMenu;
   IBOutlet NSArrayController *sessionsController;

   // Sessions Menu Items
   IBOutlet NSMenuItem *runMenuItem;
   IBOutlet NSMenuItem *runCopyMenuItem;   
   IBOutlet NSMenuItem *removeMenuItem;   
   IBOutlet NSMenuItem *showInFinderMenuItem;         

   // Profiles Drawer
   IBOutlet NSDrawer *profilesDrawer;
   IBOutlet NSTableView *profilesTableView;
   IBOutlet NSMenu *profilesContextMenu;
   IBOutlet NSArrayController *profilesController;  
   
   IBOutlet NSOutlineView *profilesOutlineView;   
   NSTimer *profileTimer; // Shitty hack to hook outlineview expansion
   
   IBOutlet NSTreeController *profileController;   
//   IBOutlet NSTextField *sessionTarget;
   IBOutlet NSComboBox *sessionTarget;   
   
   IBOutlet BWSplitView *profileView;
   IBOutlet BWAnchoredButton *profileButton;

   // Various Results Outlets
   IBOutlet NSTableView *hostsTableView;
   IBOutlet NSMenu *hostsContextMenu;
   
   IBOutlet NSTableView *portsTableView;   
   IBOutlet NSTableView *resultsPortsTableView;   
   IBOutlet NSTableView *osesTableView;      
   IBOutlet NSArrayController *portsInHostController;      
   
   IBOutlet NSArrayController *hostsInSessionController;
   IBOutlet NSArrayController *portsInSessionController;
   IBOutlet NSArrayController *osesInSessionController;
   
   // Main Menu 
   IBOutlet NSMenuItem *menuSettings;
   IBOutlet NSMenuItem *menuResults;   
   
   // Sort-descriptors for the various table views
   NSArray *osSortDescriptor;
   NSArray *hostSortDescriptor;
   NSArray *portSortDescriptor;   
   NSArray *profileSortDescriptor;      
   NSArray *sessionSortDescriptor;        
   
   // Manual-entry Outlets
   IBOutlet NSTextField *nmapCommandTextField;

   // Defines for flashing direct-entry TextField
   float nmapErrorCount;   
   NSTimer *nmapErrorTimer;
   
   NSPredicate *testy;   
   
   IBOutlet NSWindow *testWindow;
}

@property (readonly) NSArray *osSortDescriptor;
@property (readonly) NSArray *hostSortDescriptor;
@property (readonly) NSArray *portSortDescriptor;
@property (readonly) NSArray *profileSortDescriptor;
@property (readonly) NSArray *sessionSortDescriptor;

@property (readonly) NSPredicate *testy;

- (IBAction)peanut:(id)sender;

//- (void)controlTextDidEndEditing:(NSNotification *)obj;

- (IBAction) switchToScanView:(id)sender;
- (IBAction) switchToInspectorView:(id)sender;
- (void)swapView:(NSView *)oldSubview withSubView:(NSView *)newSubview inContaningView:(NSView *)containerView;

- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentTo:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;

- (IBAction)segControlClicked:(id)sender;

// Network Interface PopUp
- (void)getNetworkInterfaces;
- (void)populateInterfacePopUp;

// Sessions Drawer click-handlers
- (IBAction) sessionDrawerRun:(id)sender;
- (IBAction) sessionDrawerRunCopy:(id)sender;
- (IBAction) sessionDrawerAbort:(id)sender;
- (IBAction) sessionDrawerRemove:(id)sender;
- (IBAction) sessionDrawerShowInFinder:(id)sender;

- (Session *)clickedSessionInDrawer;
- (Session *)selectedSessionInDrawer;

// Session Manager click-handlers
- (IBAction) queueSession:(id)sender;
- (IBAction) dequeueSession:(id)sender;
- (IBAction) processQueue:(id)sender;

- (IBAction) toggleSettings:(id)sender;
- (IBAction) toggleResults:(id)sender;

- (IBAction) toggleSessionsDrawer:(id)sender;
- (IBAction) toggleProfilesDrawer:(id)sender;

- (void)addQueuedSessions;

- (void)addProfileDefaults;
//- (void)readUserDefaults;
- (IBAction)addProfile:(id)sender;
- (IBAction)deleteProfile:(id)sender;

- (IBAction)setuidNmap:(id)sender;
- (IBAction)unsetuidNmap:(id)sender;

- (void)expandProfileView:(NSTimer *)aTimer;

- (IBAction)showPrefWindow:(id)sender;

- (void)createHostsMenu;

@end
