//
//  NTCustomIconView.h
//  CocoatechFoundation
//
//  Created by Steve Gehrman on Tue Aug 27 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTIconFamily, NTFileDesc;

@interface NTCustomIconView : NSImageView
{
    NTIconFamily* mIconFamily;
    NTFileDesc* mDesc;
}

// setting a file activates copy/paste, this does not set the image
- (void)setDesc:(NTFileDesc*)desc;

- (IBAction)copy:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)clear:(id)sender;

@end
