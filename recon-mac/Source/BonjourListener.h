
#import <Cocoa/Cocoa.h>

@interface BonjourListener : NSObject {
   NSNetServiceBrowser *primaryBrowser;
   NSNetServiceBrowser *secondaryBrowser;
   NSMutableArray *services;   
   NSMutableArray *foundServices;
}

@property (readonly, retain) NSMutableArray *services;
@property (readonly, retain) NSMutableArray *foundServices;

-(IBAction)search:(id)sender;

@end
