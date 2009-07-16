//
//  NetstatController.h
//  recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Connection;

@interface NetstatController : NSObject {

   IBOutlet NSTabView *mainTabView;
   
   // Choices Tab
   IBOutlet NSMatrix *mainSelector;   

   // Netstat Tab
   NSMutableArray *connections;
   IBOutlet NSArrayController *connectionsController;
   Connection *selectedConnection;
   NSTimer *timer;
   
}

// Choices Tab
- (IBAction)chooseTask:(id)sender;

// Netstat Tab
- (IBAction)refreshConnectionsList:(id)sender;
- (void)setConnections:(NSMutableArray *)a;

@property (readwrite, retain)NSMutableArray *connections;

@end
