//
//  NTFileDeleter.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Tue May 21 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc, NTFileDeleter, NTSecureDelete;

// ------------------------------------------------------------------------------
// return NO to stop the copy, YES to continue
@protocol NTFileDeleterDelegateProtocol <NSObject>
- (BOOL)deleter:(NTFileDeleter*)deleter displayErrorAtPath:(NTFileDesc*)desc error:(OSStatus)error;
- (BOOL)deleter:(NTFileDeleter*)deleter deleteProgress:(NTFileDesc*)desc;
@end

@interface NTFileDeleter : NSObject
{
    id<NTFileDeleterDelegateProtocol> mv_delegate;
	
	NTSecureDelete* mSecureDelete;
}

+ (NTFileDeleter*)deleter:(id<NTFileDeleterDelegateProtocol>)delegate
			securityLevel:(NTDeleteSecurityLevel)securityLevel;

- (void)clearDelegate;

- (void)deleteDesc:(NTFileDesc*)desc;

@end
