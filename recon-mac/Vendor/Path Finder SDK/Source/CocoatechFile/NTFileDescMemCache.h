//
//  NTFileDescMemCache.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Fri Sep 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDescMem;

@interface NTFileDescMemCache : NSObject 
{
    NSLock *_threadLock;
    NSMutableArray* _free;
}

+ (NTFileDescMemCache*)sharedInstance;

- (NTFileDescMem*)checkout;
- (void)checkin:(NTFileDescMem*)cache;

@end

// ==============================================

@interface NTFileDescMem : NSObject
{
    NSUInteger _capacity;
    
    FSRef *_refArray;
    FSCatalogInfo *_catalogInfoArray;
    HFSUniStr255 *_nameArray;
}

- (id)initWithCapacity:(NSUInteger)capacity;
+ (id)cacheWithCapacity:(NSUInteger)capacity;

- (NSUInteger)capacity;
- (NSUInteger)minimumCapacity;

- (FSRef *)refArray;
- (FSCatalogInfo *)catalogInfoArray;
- (HFSUniStr255 *)nameArray;

@end
