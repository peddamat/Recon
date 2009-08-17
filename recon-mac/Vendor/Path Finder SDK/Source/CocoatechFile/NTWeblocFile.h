//
//  NTWeblocFile.h
//  CocoatechFile
//
//  Created by Steve Gehrman on Thu Mar 20 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTFileDesc;

@interface NTWeblocFile : NSObject
{
    NSAttributedString* _attributedString;
    
    NSString* _displayName;
    NSURL* _url;
}

// tests the file to see if it has the right type and creator
+ (BOOL)isHTTPWeblocFile:(NTFileDesc*)desc;
+ (BOOL)isTextWeblocFile:(NTFileDesc*)desc;
+ (BOOL)isServerWeblocFile:(NTFileDesc*)desc;

+ (id)weblocWithDesc:(NTFileDesc*)desc;

    // can be NSString or NSAttributedString
+ (id)weblocWithString:(id)string;
+ (id)weblocWithURL:(NSURL*)url;

    // returns nil if not a webloc, or not a server alias file at all
+ (NSURL*)urlFromWeblocFile:(NTFileDesc*)desc;
+ (NSAttributedString*)stringFromWeblocFile:(NTFileDesc*)desc;

- (BOOL)isHTTPWeblocFile;
- (BOOL)isServerWeblocFile;  // anything but http for now
- (NSURL*)url;

- (void)setDisplayName:(NSString*)name;
- (NSString*)displayName;

- (BOOL)isTextWeblocFile;
- (NSAttributedString*)attributedString;

    // create a .webloc file (path includes filename)
- (void)saveToFile:(NSString*)path; // YES for hide extension
- (void)saveToFile:(NSString*)path hideExtension:(BOOL)hideExtension;

@end
