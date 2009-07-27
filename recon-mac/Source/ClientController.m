#import "ClientController.h"


@interface ClientController ()

   @property (readwrite, retain) NSNetServiceBrowser *browser;
   @property (readwrite, retain) NSMutableArray *services;
   @property (readwrite, assign) BOOL isConnected;
   @property (readwrite, retain) NSNetService *connectedService;

@end

@implementation ClientController

@synthesize browser;
@synthesize services;
@synthesize isConnected;
@synthesize connectedService;

-(void)awakeFromNib {
   services = [NSMutableArray new];
   self.browser = [[NSNetServiceBrowser new] autorelease];
   self.browser.delegate = self;
   self.isConnected = NO;
}

-(void)dealloc {
   self.connectedService = nil;
   self.browser = nil;
   [services release];
   [super dealloc];
}

-(IBAction)search:(id)sender {
   //    [self.browser searchForServicesOfType:@"_daap._tcp" inDomain:@"local"];
   [self.browser searchForServicesOfType:@"_services._dns-sd._udp." inDomain:@""];   
}

-(IBAction)connect:(id)sender {
   NSNetService *remoteService = servicesController.selectedObjects.lastObject;
   remoteService.delegate = self;
   [remoteService resolveWithTimeout:0];
}

#pragma mark Net Service Browser Delegate Methods
-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more {
   // Queue up all the found services
   NSLog(@"More Coming: %d", more);
   [servicesController addObject:aService];
   NSLog(@"Name: %@", [aService name]);
   NSLog(@"Type: %@", [aService type]);
   
   // If we're done queueing up sessions
   if (more == NO)
   {
      // 
      ;
   }
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more {
   [servicesController removeObject:aService];
   if ( aService == self.connectedService ) self.isConnected = NO;
}

-(void)netServiceDidResolveAddress:(NSNetService *)service {
   NSLog(@"netServiceDidResolveAddress");
   NSData *txtdata = [service TXTRecordData];
   NSDictionary *txtdict = [NSNetService dictionaryFromTXTRecordData:txtdata];
   
   for (id dictKey in [txtdict allKeys])
   {
      
      NSData *dictValue = [txtdict valueForKey:dictKey];
      NSString *aStr = [[NSString alloc] initWithData:dictValue encoding:NSASCIIStringEncoding]; 
      NSLog(@"%@: %@", dictKey, aStr);
   }
   
   self.isConnected = YES;
   self.connectedService = service;
}

-(void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
   NSLog(@"Could not resolve: %@", errorDict);
}

@end
