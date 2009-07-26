
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
   
    [self.browser searchForServicesOfType:@"_services._dns-sd._udp." inDomain:@""];   
//    [self.browser searchForServicesOfType:@"_http._tcp." inDomain:@""];
}

-(IBAction)connect:(id)sender {
    NSNetService *remoteService = servicesController.selectedObjects.lastObject;
    remoteService.delegate = self;
    [remoteService resolveWithTimeout:0];
}

#pragma mark Net Service Browser Delegate Methods
-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more {
   aService.delegate = self;
   [aService resolveWithTimeout:0];
    [servicesController addObject:aService];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more {
    [servicesController removeObject:aService];
    if ( aService == self.connectedService ) self.isConnected = NO;
}

-(void)netServiceDidResolveAddress:(NSNetService *)service {
   NSData *txtdata = [service TXTRecordData];
   NSDictionary *txtdict = [NSNetService dictionaryFromTXTRecordData:txtdata];
   //ANSLog(@"TEST: %@", [txtdict allKeys]);
   
   id dictKey;
   NSArray *allKeys = [txtdict allKeys];   
   NSEnumerator *e = [allKeys objectEnumerator];
   
   while (dictKey = [e nextObject])
   {
      
      NSData *dictValue = [txtdict valueForKey:dictKey];
      NSString *aStr = [[NSString alloc] initWithData:dictValue encoding:NSASCIIStringEncoding]; 
      //ANSLog(@"%@", aStr);
   }
   
    self.isConnected = YES;
    self.connectedService = service;
}

-(void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
    //ANSLog(@"Could not resolve: %@", errorDict);
}

@end
