//
//  NTSecureDelete.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 6/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTSecureDelete : NSObject {
	NTDeleteSecurityLevel mSecurityLevel;
	int mFile;
	off_t mFileSize;
	unsigned char *mBuffer;
	u_int32_t mBuffSize;
	int mRandFile;
}

+ (NTSecureDelete*)secureDelete:(NTDeleteSecurityLevel)securityLevel;

- (OSStatus)deleteFile:(const char*)path;

@end
