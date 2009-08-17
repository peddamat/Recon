//
//  MyDocument.h
//  Path Finder Remote
//
//  Created by Steve Gehrman on 8/29/04.
//  Copyright __MyCompanyName__ 2004 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

#import <PathFinderRemote/PathFinderRemote.h>

@interface MyDocument : NSDocument <NTPathFinderRemoteDelegateProtocol>
{
	IBOutlet id mOutputTextView;
	IBOutlet NSTextField* mPathText;
	IBOutlet NSTextField* mPathText2;
	IBOutlet NSPopUpButton* mCommandPopUp;
	
	NSFont *mFont;
	NTPathFinderRemote* mPathFinderRemote;
}
@end
