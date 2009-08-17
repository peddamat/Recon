//
//  InspectorController.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ManagingViewController.h"

@class NetstatConnection;
@class SessionController;
@class SessionManager;

@class BonjourListener;

@interface BasicViewController : ManagingViewController {

   // Global outlets
   IBOutlet NSPopUpButton *taskSelectionPopUp;
   IBOutlet NSButton *scanButton;
   IBOutlet NSProgressIndicator *refreshIndicator;
      
   // See connected computers mode
   NSMutableArray *connections;

   BOOL autoRefresh;
   BOOL resolveHostnames;
   BOOL doneRefresh;
   BOOL showSpinner;
   IBOutlet NSButton *autoRefreshButton;
   IBOutlet NSButton *resolveHostnamesButton;   
   IBOutlet NSArrayController *connectionsController;
   
   // Text Fields for host entry
   IBOutlet NSTextField *hostsTextField;
   IBOutlet NSTextField *hostsTextFieldLabel;   
   
   IBOutlet NSScrollView *regularHostsScrollView;
   IBOutlet NSScrollView *netstatHostsScrollView;
   IBOutlet NSScrollView *bonjourHostsScrollView;
   
	NSTask *task;      
	NSMutableData *standardOutput;
	NSMutableData *standardError;
   
   BonjourListener *bonjourListener;
   NSMutableArray *foundServices;
   IBOutlet NSArrayController *foundServicesController;

   IBOutlet NSArrayController *bonjourConnectionsController;
   IBOutlet NSOutlineView *foundServicesOutlineView;
	NSRect bigFramePosition;
	NSRect smallFramePosition;
   IBOutlet NSView *hider;

   IBOutlet NSView *workspaceBasicContent;   
   IBOutlet NSView *workspaceBasicContentBonjour;   
   IBOutlet NSView *workspaceBasicContentNetstat;     
   
   IBOutlet NSView *targetBarBasicContent;
   
   IBOutlet NSMenu *netstatContextMenu;   
   
   
   // Sort-descriptors for the various table views
   NSArray *osSortDescriptor;
   NSArray *hostSortDescriptor;
   NSArray *portSortDescriptor;   
   NSArray *profileSortDescriptor;      
   NSArray *sessionSortDescriptor;           
}

@property (readwrite, retain)NSMutableArray *connections;
@property (readwrite, retain)NSMutableArray *foundServices;
@property (readwrite, assign)BOOL autoRefresh;
@property (readwrite, assign)BOOL resolveHostnames;
@property (readwrite, assign)BOOL doneRefresh;
@property (readwrite, assign)BOOL showSpinner;

@property (readonly) NSArray *osSortDescriptor;
@property (readonly) NSArray *hostSortDescriptor;
@property (readonly) NSArray *portSortDescriptor;
@property (readonly) NSArray *profileSortDescriptor;
@property (readonly) NSArray *sessionSortDescriptor;

@property (readonly) NSView *targetBarBasicContent;

- (IBAction)launchScan:(id)sender;
- (IBAction)changeInspectorTask:(id)sender;

// Find computers mode
int bitcount (unsigned int n);
- (int)cidrForInterface:(NSString *)ifName;
- (IBAction)searchLocalNetwork:(id)sender;
- (IBAction)searchLocalNetworkForPrinters:(id)sender;
- (IBAction)searchLocalNetworkForShares:(id)sender;
- (NSString *)grabDefaultIp;
- (IBAction)checkForServices:(id)sender;

// See connected computers mode
- (IBAction)refreshConnectionsList:(id)sender;
- (void)setConnections:(NSMutableArray *)a;
- (IBAction)clickAutoRefresh:(id)sender;
- (IBAction)clickResolveHostnames:(id)sender;

- (void)createNetstatMenu;
- (IBAction)handleNetstatMenuClick:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
- (void)menuNeedsUpdate:(NSMenu *)menu;

@end
