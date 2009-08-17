//
//  NTLoginItemMgr.h
//  CocoaTechBase
//
//  Created by sgehrman on Sun Jun 17 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kLaunchAfterLogin @"kLaunchAfterLogin"

@interface NTLoginItemMgr : NTSingletonObject
{
}

- (BOOL)isLoginItem:(NTFileDesc*)theDesc;
- (void)removeLoginItem:(NTFileDesc*)theDesc;
- (void)addLoginItem:(NTFileDesc*)theDesc;
@end
