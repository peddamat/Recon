#import <Cocoa/Cocoa.h>

@interface ManagingViewController : NSViewController {
   
   NSManagedObjectContext *managedObjectContext;
   NSArrayController *sessionsArrayController;   
   NSArrayController *profilesArrayController;
   
   NSArrayController *notesInHostArrayController;
   NSArrayController *hostsInSessionArrayController; 
      
   NSView *workspacePlaceholder;
   
}

@property (retain) NSManagedObjectContext *managedObjectContext;
@property (retain) NSArrayController *sessionsArrayController;
@property (retain) NSArrayController *profilesArrayController;

@property (retain) NSArrayController *notesInHostArrayController;
@property (retain) NSArrayController *hostsInSessionArrayController;

@property (retain) NSView *workspacePlaceholder;

@end
