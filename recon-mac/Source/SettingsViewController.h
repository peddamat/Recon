//
//  SettingsViewController.h
//  recon
//
//  Created by Sumanth Peddamatham on 8/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ManagingViewController.h"

@interface SettingsViewController : ManagingViewController {
   
   IBOutlet NSView *workspaceSettingsContent;   
   IBOutlet NSView *targetBarSettingsContent; 
   IBOutlet NSView *sideBarSettingsContent;
   
   IBOutlet NSScrollView *workspaceSettingsScrollView;   
   
   // TCP/Non-TCP/Timings Popup
   IBOutlet NSPopUpButton *tcpScanPopUp;
   IBOutlet NSPopUpButton *nonTcpScanPopUp;
   IBOutlet NSPopUpButton *timingTemplatePopUp;   
   
   IBOutlet NSOutlineView *profilesOutlineView;
   IBOutlet NSTreeController *profilesTreeController;
   
   // Sort-descriptors for the various table views
   NSArray *osSortDescriptor;
   NSArray *hostSortDescriptor;
   NSArray *portSortDescriptor;   
   NSArray *profileSortDescriptor;      
   NSArray *sessionSortDescriptor;        
   
}

@property (readonly) NSArray *osSortDescriptor;
@property (readonly) NSArray *hostSortDescriptor;
@property (readonly) NSArray *portSortDescriptor;
@property (readonly) NSArray *profileSortDescriptor;
@property (readonly) NSArray *sessionSortDescriptor;

@property (readonly) NSView *targetBarSettingsContent;

- (void)expandProfileView;
- (IBAction)addProfile:(id)sender;
- (IBAction)deleteProfile:(id)sender;

@end
