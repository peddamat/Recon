//
//  InspectorController.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Connection;
@class SessionController;
@class SessionManager;

@interface InspectorController : NSObject {

   
   // Main PopUpButton at top
   IBOutlet NSPopUpButton *taskSelectionPopUp;

   IBOutlet NSButton *scanButton;
   
   // Find computers mode
   NSPredicate *testy;      
   SessionManager *SessionManager;
   IBOutlet NSArrayController *sessionsController;
   
   // See connected computers mode
   NSTimer *timer;   
   NSMutableArray *connections;

   Connection *selectedConnection;
   BOOL autoRefresh;
   BOOL resolveHostnames;
   BOOL doneRefresh;
   IBOutlet NSButton *autoRefreshButton;
   IBOutlet NSButton *resolveHostnamesButton;

   
   IBOutlet NSArrayController *connectionsController;
   
   // Text Fields for host entry
   IBOutlet NSTextField *hostsTextField;
   IBOutlet NSTextField *hostsTextFieldLabel;   
   
   IBOutlet NSScrollView *regularHostsScrollView;
   IBOutlet NSScrollView *netstatHostsScrollView;
}

@property (readwrite, retain)NSMutableArray *connections;
@property (readwrite, assign)BOOL autoRefresh;
@property (readwrite, assign)BOOL resolveHostnames;

- (IBAction)changeInspectorTask:(id)sender;
- (IBAction)launchScan:(id)sender;

// Find computers mode
int bitcount (unsigned int n);
- (int)cidrForInterface:(NSString *)ifName;
- (IBAction)searchLocalNetwork:(id)sender;
   
// See connected computers mode
- (IBAction)refreshConnectionsList:(id)sender;
- (void)setConnections:(NSMutableArray *)a;
- (IBAction)clickAutoRefresh:(id)sender;
- (IBAction)clickResolveHostnames:(id)sender;

@end
