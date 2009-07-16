// 
//  Host.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Host.h"

#import "OperatingSystem.h"
#import "Port.h"
#import "Session.h"

@implementation Host 

@dynamic ipv4Address;
@dynamic macAddress;
@dynamic uptimeLastBoot;
@dynamic status;
@dynamic hostname;
@dynamic statusReason;
@dynamic distance;
@dynamic uptimeSeconds;
@dynamic operatingsystems;
@dynamic ports;
@dynamic session;

@end
