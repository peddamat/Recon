// 
//  Host.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/6/09.
//  Copyright 2009 bafoontecha.com. All rights reserved.
//

#import "Host.h"

#import "Port.h"
#import "Session.h"

@implementation Host 

@dynamic ipv4Address;
@dynamic macAddress;
@dynamic uptimeLastBoot;
@dynamic status;
@dynamic hostname;
@dynamic statusReason;
@dynamic uptimeSeconds;
@dynamic ports;
@dynamic session;

- (NSString *)ipAndHostname
{
   NSString *ipv4Address = [[self ipv4Address] retain];
//   NSString *hostname = [self hostname];
//   if (!hostname)
//      return ipv4Address;
//      
//   return [NSString stringWithFormat:@"%@ (%@)", ipv4Address, hostname];
   
   return [NSString stringWithFormat:@"%@ (%@)", ipv4Address,@"ipv4Address"];   
}

@end
