//
//  NTSampleMenuPlugin.h
//  Image Converter
//
//  Created by Steve Gehrman on Wed Mar 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTMenuPluginProtocol.h"

@interface NTSampleMenuPlugin : NSObject <NTMenuPluginProtocol>
{
    id<NTPathFinderPluginHostProtocol> mHost;
}

@end
