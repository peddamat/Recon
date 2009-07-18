//
//  Connection.h
//  Recon
//
//  Created by Sumanth Peddamatham on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Connection : NSObject {
   NSString *localIP;
   NSString *localPort;   
   NSString *remoteIP;
   NSString *remotePort;   
   NSString *status;   
}

@property (readwrite, copy) NSString *localIP;
@property (readwrite, copy) NSString *localPort;
@property (readwrite, copy) NSString *remoteIP;
@property (readwrite, copy) NSString *remotePort;
@property (readwrite, copy) NSString *status;

- (id)initWithLocalIP:(NSString *)localIP 
         andLocalPort:(NSString *)localPort 
          andRemoteIP:(NSString *)remoteIP 
         andRemotePort:(NSString *)remotePort 
            andStatus:(NSString *)status;

@end
