//
//  Connection.m
//  recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Connection.h"


@implementation Connection

- (id)init
{
   return [self initWithLocalIP:@"HI" 
                    andLocalPort:@"HI"            
                    andRemoteIP:@"HI" 
                    andRemotePort:@"HI"            
                      andStatus:@"HI"];
}

- (id)initWithLocalIP:(NSString *)lIP 
         andLocalPort:(NSString *)lP 
          andRemoteIP:(NSString *)rIP 
        andRemotePort:(NSString *)rP 
            andStatus:(NSString *)s;
{
   [super init];
   
   self.localIP = lIP;
   self.localPort = lP;   
   self.remoteIP = rIP;
   self.remotePort = rP;   
   self.status = s;
   
   return self;
}

- (void)dealloc
{
   [localIP release];
   [localPort release];   
   [remoteIP release];
   [remotePort release];   
   [status release];   
   [super dealloc];
}

@synthesize localIP;
@synthesize localPort;
@synthesize remoteIP;
@synthesize remotePort;
@synthesize status;

@end
