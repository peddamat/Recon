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

   IBOutlet NSPopUpButton *taskSelectionPopUp;
   
   // Find computers mode
   SessionManager *SessionManager;
   IBOutlet NSArrayController *sessionsController;
   NSPredicate *testy;   
   
   // See connected computers mode
   NSMutableArray *connections;
   IBOutlet NSArrayController *connectionsController;
   Connection *selectedConnection;
   NSTimer *timer;
   IBOutlet NSButton *alwaysRefresh;
   
   IBOutlet NSTextField *hostsTextField;
   IBOutlet NSTextField *hostsTextFieldLabel;   
   
   IBOutlet NSScrollView *regularHostsScrollView;
   IBOutlet NSScrollView *netstatHostsScrollView;
}

@property (readonly) NSPredicate *testy;
@property (readwrite, retain)NSMutableArray *connections;

- (IBAction)changeInspectorTask:(id)sender;
- (IBAction)launchScan:(id)sender;

// Find computers Tab
int bitcount (unsigned int n);
- (int)cidrForInterface:(NSString *)ifName;
- (IBAction)searchLocalNetwork:(id)sender;
   
// Netstat Tab
- (IBAction)refreshConnectionsList:(id)sender;
- (void)autoRefreshConnections;
- (void)setConnections:(NSMutableArray *)a;

@end
