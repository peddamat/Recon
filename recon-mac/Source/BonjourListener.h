
#import <Cocoa/Cocoa.h>

@interface BonjourListener : NSObject {
   NSNetServiceBrowser *primaryBrowser;
   NSNetServiceBrowser *secondaryBrowser;
   NSMutableArray *services;
//   IBOutlet NSArrayController *servicesController;
   
   NSMutableArray *foundServices;
   IBOutlet NSArrayController *foundServicesController;   
   
   int servicesCount;
}

@property (readonly, retain) NSMutableArray *services;
@property (readonly, retain) NSMutableArray *foundServices;

-(IBAction)search:(id)sender;

@end
