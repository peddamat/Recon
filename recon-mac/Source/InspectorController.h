//
//  InspectorController.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NetstatConnection;
@class SessionController;
@class SessionManager;

@class BonjourListener;

@interface InspectorController : NSObject {

   // Global outlets
   IBOutlet NSPopUpButton *taskSelectionPopUp;
   IBOutlet NSButton *scanButton;
   IBOutlet NSProgressIndicator *refreshIndicator;
   
   // Find computers mode  
   SessionManager *SessionManager;
   IBOutlet NSArrayController *sessionsController;
   
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
   NSMutableDictionary *root;   
   IBOutlet NSOutlineView *foundServicesOutlineView;
	NSRect bigFramePosition;
	NSRect smallFramePosition;
   IBOutlet NSView *hider;
}

@property (readwrite, retain)NSMutableArray *connections;
@property (readwrite, retain)NSMutableArray *foundServices;
@property (readwrite, assign)BOOL autoRefresh;
@property (readwrite, assign)BOOL resolveHostnames;
@property (readwrite, assign)BOOL doneRefresh;
@property (readwrite, assign)BOOL showSpinner;

@property (assign,readonly) NSMutableDictionary *root;

- (IBAction)changeInspectorTask:(id)sender;
- (IBAction)launchScan:(id)sender;

// Find computers mode
int bitcount (unsigned int n);
- (int)cidrForInterface:(NSString *)ifName;
- (IBAction)searchLocalNetwork:(id)sender;
- (IBAction)checkForServices:(id)sender;

// See connected computers mode
- (IBAction)refreshConnectionsList:(id)sender;
- (void)setConnections:(NSMutableArray *)a;
- (IBAction)clickAutoRefresh:(id)sender;
- (IBAction)clickResolveHostnames:(id)sender;

@end
