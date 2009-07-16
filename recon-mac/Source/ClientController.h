
#import <Cocoa/Cocoa.h>

@interface ClientController : NSObject {
    BOOL isConnected;
    NSNetServiceBrowser *browser;
    NSNetService *connectedService;
    NSMutableArray *services;
    IBOutlet NSArrayController *servicesController;
}

@property (readonly, retain) NSMutableArray *services;
@property (readonly, assign) BOOL isConnected;

-(IBAction)search:(id)sender;
-(IBAction)connect:(id)sender;

@end
