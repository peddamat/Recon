
#import "BonjourListener.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>


@interface BonjourListener ()

@property (readwrite, retain) NSNetServiceBrowser *primaryBrowser;
@property (readwrite, retain) NSNetServiceBrowser *secondaryBrowser;
@property (readwrite, retain) NSMutableArray *services;
@property (readwrite, retain) NSMutableArray *foundServices;

@end

@implementation BonjourListener

@synthesize primaryBrowser;
@synthesize secondaryBrowser;
@synthesize services;
@synthesize foundServices;

-(id)init {
   if (self = [super init])
   {   
      NSLog(@"Bonjour!");
      self.services = [NSMutableArray new];
      self.foundServices = [NSMutableArray new];   
      self.primaryBrowser = [[NSNetServiceBrowser new] autorelease];
      self.primaryBrowser.delegate = self;
      self.secondaryBrowser = [[NSNetServiceBrowser new] autorelease];
      self.secondaryBrowser.delegate = self;
      
      servicesCount = 0;
   }   
   
   return self;
}

-(void)dealloc {
   self.primaryBrowser = nil;
   self.secondaryBrowser = nil;
   [services release];   
   [foundServices release];
   [super dealloc];
}

-(IBAction)search:(id)sender {
   //    [self.primaryBrowser searchForServicesOfType:@"_daap._tcp" inDomain:@""];
   //    [self.primaryBrowser searchForServicesOfType:@"_http._tcp" inDomain:@""];   
   //    [self.primaryBrowser searchForServicesOfType:@"_rsp._tcp" inDomain:@""];   
   NSLog(@"BonjourListener: search");
   [self.foundServices removeAllObjects];
   [self.primaryBrowser stop];
   [self.secondaryBrowser stop];   
   [self.primaryBrowser searchForServicesOfType:@"_services._dns-sd._udp." inDomain:@""];   
}

#pragma mark Net Service Browser Delegate Methods
-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more {
   if (aBrowser == self.primaryBrowser)
   {
      servicesCount++;
      
      [services addObject:aService];
      NSLog(@"Name: %@", [aService name]);
      NSLog(@"Type: %@", [aService type]);
      
      if (more == NO)
      {
         NSNetService *s = [services objectAtIndex:0];
         NSString *name = [s name];
         NSString *type = [s type];
         NSArray *a = [type componentsSeparatedByString:@"."];
         NSString *newSearch = [NSString stringWithFormat:@"%@.%@", name, [a objectAtIndex:0]];
         
         [services removeObjectAtIndex:0];
         [self.secondaryBrowser searchForServicesOfType:newSearch inDomain:@""];            
      }
   }
   
   if (aBrowser == self.secondaryBrowser)
   {
      NSLog(@"\nSecond");
      [aService retain];
      aService.delegate = self;
      [aService resolveWithTimeout:0];      
      
      [secondaryBrowser stop];
      
      if ([services count] > 0)
      {
         NSNetService *s = [services objectAtIndex:0];
         NSString *name = [s name];
         NSString *type = [s type];
         NSArray *a = [type componentsSeparatedByString:@"."];
         NSString *newSearch = [NSString stringWithFormat:@"%@.%@", name, [a objectAtIndex:0]];
         
         [services removeObjectAtIndex:0];
         [self.secondaryBrowser searchForServicesOfType:newSearch inDomain:@""];            
      }      
   }
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more {
//   [servicesController removeObject:aService];
//   if ( aService == self.connectedService ) self.isConnected = NO;
}

-(void)netServiceDidResolveAddress:(NSNetService *)service {
   NSLog(@"netServiceDidResolveAddress");
   
   NSMutableDictionary *newService = [[NSMutableDictionary alloc] init];

   uint8_t name[SOCK_MAXADDRLEN];   
   [[[service addresses] lastObject] getBytes:name];
   struct sockaddr_in *temp_addr = (struct sockaddr_in *)name;
   NSString *ipaddr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr)->sin_addr)];
   
   [newService setObject:ipaddr forKey:@"_ipaddr"];
   [newService setObject:[service domain] forKey:@"_domain"];
   [newService setObject:[service hostName] forKey:@"_hostname"];
   [newService setObject:[service name] forKey:@"_name"];
   [newService setObject:[service type] forKey:@"_type"];
      
   NSDictionary *txtdict = [NSNetService dictionaryFromTXTRecordData:[service TXTRecordData]];
      
   for (id dictKey in [txtdict allKeys])
   {
      
      NSData *dictValue = [txtdict valueForKey:dictKey];
      NSString *aStr = [[NSString alloc] initWithData:dictValue encoding:NSASCIIStringEncoding]; 
      // To use Bindings, we have to replace spaces and '-' with underscores
      dictKey = [dictKey stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
      dictKey = [dictKey stringByReplacingOccurrencesOfString:@" " withString:@"_"];
      [newService setObject:aStr forKey:dictKey];
//      NSLog(@"%@: %@", dictKey, aStr);
   }
   
   [foundServices addObject:newService];
   
//   if ([foundServices count] == 3)
//   {
//      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];      
//      [nc postNotificationName:@"BAFfoundBonjourServices" object:self];  
//   }   
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];      
   [nc postNotificationName:@"BAFfoundBonjourServices" object:newService];  
}

-(void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
   NSLog(@"Could not resolve: %@", errorDict);
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser {
   NSLog(@"About to search!\n");
}

@end
