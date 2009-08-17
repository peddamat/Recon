/*
 **  iTerm.h
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: header file for iTerm.app.
 **
 */

#ifndef _ITERM_H_
#define _ITERM_H_


#define NSLogRect(aRect)	NSLog(@"Rect = %f,%f,%f,%f", (aRect).origin.x, (aRect).origin.y, (aRect).size.width, (aRect).size.height)

#import "iTermController.h"
#import "ITAddressBookMgr.h"
#import "PreferencePanel.h"
#import "ITTerminalView.h"
#import "ITTerminalWindowController.h"

#endif // _ITERM_H_
