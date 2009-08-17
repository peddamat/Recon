//
//  NTPartitionInfo.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 2/17/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NTPartitionInfo : NSObject {

}

+ (NSArray*)siblingEjectablePartitionsForVolume:(NTVolume*)volume;

@end
