//
//  NTSVNAskForStringController.h
//  SVNModulePlugin
//
//  Created by Steve Gehrman on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NTSVNAskForStringControllerDelegate <NSObject>
- (void)askForString_result:(NSString*)string canceled:(BOOL)canceled context:(id)context;
@end

@interface NTSVNAskForStringController : NSWindowController 
{
	id<NTSVNAskForStringControllerDelegate> mDelegate;
	
	IBOutlet NSObjectController* mObjectController;
	NSMutableDictionary *mModel;
	id mContext;
}

+ (void)ask:(NSString*)title
sheetWindow:(NSWindow*)sheetWindow 
   delegate:(id<NTSVNAskForStringControllerDelegate>)delegate
	context:(id)context;

@end
