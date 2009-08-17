//
//  NTLaunchServiceHacks.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Sun Mar 23 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class NTFSRefObject;

@interface NTLaunchServiceHacks : NSObject
{
}

+ (OSStatus)LSCopyDisplayNameForRef:(NTFSRefObject*)fsRefObject outDisplayName:(CFStringRef *)outDisplayName;
+ (OSStatus)LSCopyItemInfoForRef:(NTFSRefObject*)fsRefObject whichInfo:(LSRequestedInfo)whichInfo itemInfo:(LSItemInfoRecord*)itemInfoPtr;

+ (OSStatus)LSSetWeakBindingForType:(OSType)inType			// kLSUnknownType if no type binding performed
                            creator:(OSType)inCreator		// always kLSUnknownCreator
                          extension:(NSString*)inExtension	// or NULL if no extension binding is done
                               role:(LSRolesMask)inRole			// role for the binding
                        application:(FSRef *)inAppRefOrNil;	// bound app or NULL to clear the binding

+ (OSStatus)LSGetStrongBindingForRef:(const FSRef *)inItemRef
                           outAppRef:(FSRef *)outAppRef;

+ (OSStatus)LSSetStrongBindingForRef:(const FSRef *)inItemRef
                         application:(FSRef *)inAppRefOrNil;	// NULL to clear the strong binding


@end
