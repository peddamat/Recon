//
//  NTLaunchServiceHacks.m
//  CocoatechFile
//
//  Created by Steve Gehrman on Sun Mar 23 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import "NTLaunchServiceHacks.h"
#import "NTFSRefObject.h"

// undocumented function call
extern OSStatus _LSSetWeakBindingForType(OSType        inType,			// kLSUnknownType if no type binding performed
                         OSType        inCreator,		// always kLSUnknownCreator
                         CFStringRef   inExtension,	// or NULL if no extension binding is done
                         LSRolesMask   inRole,			// role for the binding
                         FSRef *       inAppRefOrNil);	// bound app or NULL to clear the binding

// undocumented function call
extern OSStatus _LSGetStrongBindingForRef(const FSRef *  inItemRef,
                          FSRef *        outAppRef);

// undocumented function call
extern OSStatus _LSSetStrongBindingForRef(const FSRef *  inItemRef,
                          FSRef *        inAppRefOrNil);	// NULL to clear the strong binding

// undocumented structure
struct LSExtendedFSRefInfo
{
    FSRef * ref; /* may be null if CFURLRef used */

    CFURLRef url; /* may be null if FSRef used */

    HFSUniStr255 * name; /* may be null if CFURLRef used */

    FSCatalogInfoBitmap infoFetched; /* may be null if CFURLRef used */

    FSCatalogInfo * info; /* may be null if CFURLRef used */

};
typedef struct LSExtendedFSRefInfo LSExtendedFSRefInfo;

// undocumented function call
extern OSStatus _LSCopyDisplayNameForRefInfo(const LSExtendedFSRefInfo * inRefInfo,
                                             CFStringRef * outDisplayName);

// undocumented function call
extern OSStatus _LSCopyItemInfoForRefInfo(const LSExtendedFSRefInfo * inRefInfo,
                                          LSRequestedInfo inWhichInfo,
                                          LSItemInfoRecord * outItemInfo);

@implementation NTLaunchServiceHacks

// FinderInfo and the name should be set to avoid a call to FSGetCatalogInfo
+ (OSStatus)LSCopyDisplayNameForRef:(NTFSRefObject*)fsRefObject outDisplayName:(CFStringRef *)outDisplayName;
{
    LSExtendedFSRefInfo info;

    // make sure these bits are set before making the call
//    [fsRefObject updateCatalogInfo:??????];

    info.infoFetched = [fsRefObject catalogInfoBitmap];
    info.info = [fsRefObject catalogInfo];
    info.name = nil; // [fsRefObject hfsName]; // doesn't work when the name is set
    info.url = nil;
    info.ref = [fsRefObject ref];

    return _LSCopyDisplayNameForRefInfo(&info, outDisplayName);
}

// the FSCatalogInfo should have at least kLSMinCatInfoBitmap to avoid an additional call to FSGetCatalogInfo
+ (OSStatus)LSCopyItemInfoForRef:(NTFSRefObject*)fsRefObject whichInfo:(LSRequestedInfo)whichInfo itemInfo:(LSItemInfoRecord*)itemInfo;
{
    LSExtendedFSRefInfo info;

    // make sure these bits are set before making the call
    [fsRefObject updateCatalogInfo:kLSMinCatInfoBitmap];

    info.infoFetched = [fsRefObject catalogInfoBitmap];
    info.info = [fsRefObject catalogInfo];
    info.name = nil; // [fsRefObject hfsName]; // doesn't work when the name is set
    info.url = nil;
    info.ref = [fsRefObject ref];

    return _LSCopyItemInfoForRefInfo(&info, whichInfo, itemInfo);
}

+ (OSStatus)LSSetWeakBindingForType:(OSType)inType			// kLSUnknownType if no type binding performed
                            creator:(OSType)inCreator		// always kLSUnknownCreator
                          extension:(NSString*)inExtension	// or NULL if no extension binding is done
                               role:(LSRolesMask)inRole			// role for the binding
                        application:(FSRef *)inAppRefOrNil;	// bound app or NULL to clear the binding
{
    // undocumented function call
    return _LSSetWeakBindingForType(inType,			// kLSUnknownType if no type binding performed
                                    inCreator,		// always kLSUnknownCreator
                                    (CFStringRef)inExtension,	// or NULL if no extension binding is done
                                    inRole,			// role for the binding
                                    inAppRefOrNil);	// bound app or NULL to clear the binding

}

+ (OSStatus)LSGetStrongBindingForRef:(const FSRef *)inItemRef
                           outAppRef:(FSRef *)outAppRef;
{
    // undocumented function call
    return _LSGetStrongBindingForRef(inItemRef, outAppRef);
}

+ (OSStatus)LSSetStrongBindingForRef:(const FSRef *)inItemRef
                         application:(FSRef *)inAppRefOrNil;	// NULL to clear the strong binding
{
    // undocumented function call
    return _LSSetStrongBindingForRef(inItemRef, inAppRefOrNil);	// NULL to clear the strong binding
}

@end

