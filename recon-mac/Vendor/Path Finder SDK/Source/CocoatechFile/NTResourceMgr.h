//
//  NTResourceMgr.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue Jul 23 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTFileDesc;

@interface NTResourceMgr : NSObject
{
    BOOL _isValid;
    BOOL _useDataFork;
    NSDictionary *_resourceMap;
    NSData* _fileData;
    NTFileDesc* _desc;
}

- (id)initWithDesc:(NTFileDesc*)desc useDataFork:(BOOL)useDataFork;
+ (id)mgrWithDesc:(NTFileDesc*)desc; //  defaults to rsrc fork
+ (id)mgrWithDesc:(NTFileDesc*)desc useDataFork:(BOOL)useDataFork;

- (BOOL)isValid;  // returns no if wasn't able to read and parse the resource header
- (NSData*)resourceForType:(OSType)resType;
- (NSData*)resourceForType:(OSType)resType resID:(int)resID;

- (NSArray*)resourceTypes;
- (NSArray*)resouceIDsForType:(OSType)resType;

- (NSArray*)resourceInfosForType:(OSType)resType;

@end

@interface NSData (ResourceForkAdditions)
// Reading the fork automatically handles the ._ files (their in apple double format)
+ (NSData*)resourceData:(NTFileDesc*)file rsrcFork:(BOOL)rsrcFork;
@end
