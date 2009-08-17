/*
 *  NTWindowThemeSupport.h
 *
 *  Created by Steve Gehrman on 5/5/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

// listen for notification
#define kNTWindowThemeSupportNotification @"NTWindowThemeSupportNotification"

// color themes are global so any view can access it globaly.  Less pointers to pass around and retain.
@interface NSApplication (WindowThemeSupport)
- (NSDictionary*)themeForWindow:(NSWindow*)window;
@end

// keys for returned dictionary
#define kNTTheme_textColor @"textColor"
#define kNTTheme_backgroundColor @"backgroundColor"
#define kNTTheme_alternatingRowColor @"alternatingRowColor"
#define kNTTheme_gridColor @"gridColor"
#define kNTTheme_infoTextColor @"infoTextColor"
#define kNTTheme_backgroundPatternColor @"backgroundPatternColor"
#define kNTTheme_controlColor @"controlColor"

/* 
Example:

NSDictionary *theme = [NSApp themeForWindow:[self window]];
NSColor *color = [NSColor whiteColor];

if (theme)
color = [theme objectForKey:kNTThemeBackgroundColor];

[color set];
...
*/
