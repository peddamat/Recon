//
//  AdvancedViewController.h
//  recon
//
//  Created by Sumanth Peddamatham on 8/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ManagingViewController.h"
#import "NSManagedObjectContext-helper.h"

#import <BWToolkitFramework/BWSplitView.h>

#import <WebKit/WebKit.h>

@class MyTerminalView;
@class ColorGradientView;
@class NotesTableView;

@interface AdvancedViewController : ManagingViewController {

   IBOutlet NSView *workspaceAdvancedContent;   
   IBOutlet NSView *targetBarAdvancedContent;   
   IBOutlet NSView *sideBarAdvancedContent;   
   
   IBOutlet NSView *outputPlaceholder;
   IBOutlet NSView *outputPlaceholderOffScreen;
   
   IBOutlet NSView *portsInHostView;
   IBOutlet NSView *scriptOutputView;
   IBOutlet MyTerminalView *consoleOutputView;
   IBOutlet NSView *hostsInSessionView;
   
   // Various Results Outlets
   IBOutlet NSTableView *hostsTableView;
   IBOutlet NSMenu *hostsContextMenu;

   IBOutlet NSMenu *portsInHostContextMenu;   
   IBOutlet NSMenu *portsInSessionContextMenu;   
   
   IBOutlet NSComboBox *sessionTarget;      
//   IBOutlet NSTextField *sessionTarget;
   
   IBOutlet NSSegmentedControl *advancedModeSwitchBar;
   
   IBOutlet NSTableView *portsTableView;   
   IBOutlet NSTableView *resultsPortsTableView;   
   IBOutlet NSTableView *osesTableView;  
   IBOutlet NotesTableView *notesTableView;
   
   IBOutlet NSArrayController *portsInHostController;   
   IBOutlet NSArrayController *notesInHostController;   
   IBOutlet NSArrayController *hostsInSessionController;
   IBOutlet NSArrayController *portsInSessionController;
   IBOutlet NSArrayController *osesInSessionController;
      
   // Sort-descriptors for the various table views
   NSArray *osSortDescriptor;
   NSArray *hostSortDescriptor;
   NSArray *portSortDescriptor;   
   NSArray *profileSortDescriptor;     
   NSArray *sessionSortDescriptor; 
   NSArray *notesSortDescriptor;  

   IBOutlet ColorGradientView *notesGradientView;
   
   IBOutlet NSTextField *notesLabel;   
   IBOutlet NSTextField *sessionsLabel;
   IBOutlet NSTextField *ipTextField;
   IBOutlet NSTextField *hostStatusTextField;   

   IBOutlet BWSplitView *mainSplitView;
   IBOutlet BWSplitView *sidebarSplitView;  
   IBOutlet BWSplitView *notesInternalView;
   IBOutlet BWSplitView *sessionsInternalView;
   
   IBOutlet NSTextView *notesTextView;
   
   IBOutlet NSButton *testy;
      
   IBOutlet NSScrollView *sessionsScrollView;

}

@property (readonly) NSArray *osSortDescriptor;
@property (readonly) NSArray *hostSortDescriptor;
@property (readonly) NSArray *portSortDescriptor;
@property (readonly) NSArray *profileSortDescriptor;
@property (readonly) NSArray *sessionSortDescriptor;
@property (readonly) NSArray *notesSortDescriptor;

@property (readonly) NSView *targetBarAdvancedContent;

@property (readonly) MyTerminalView *consoleOutputView;

- (void)createHostsMenu;
- (void)createPortsInHostMenu;
- (void)createPortsInSessionMenu;

- (IBAction)modeSwitch:(id)sender;

- (IBAction)switchToPortsInHost:(id)sender;
- (IBAction)switchToScriptOutput:(id)sender;
- (IBAction)switchToConsole:(id)sender;
- (IBAction)switchToHostsInSession:(id)sender;

- (IBAction)segControlClicked:(id)sender;

- (void)runCommandInNewConsoleTab:(NSString *)command;
- (void)addStringToCurrentConsoleTab:(NSString *)string;

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal;

- (IBAction)focusInputField:(id)sender;

- (void)openNotesInternalView;
- (void)openSessionsInternalView;
- (void)closeNotesInternalView;
- (void)closeSessionsInternalView;

- (IBAction)addNote:(id)sender;

@end
