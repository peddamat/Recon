//
//  NTSizeCalculatorTreeOperation.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NTOperation.h"

@class NTSizeCalculatorTreeRoot;

typedef enum NTTreeOperationType {
	kNTTreeOperation_processNewFolders,
	kNTTreeOperation_processRefreshMessages,
	kNTTreeOperation_calculateTreeNode,
} NTTreeOperationType;

@interface NTSizeCalculatorTreeOperation : NTOperation 
{
	NTTreeOperationType type;
	
	// only valid for kNTTreeOperation_calculateTreeNode
	NSString* calcingFolderKey;  // dictionary key of folder being calced, allows us to cancel if needed
}

@property (assign) NTTreeOperationType type;
@property (retain) NSString* calcingFolderKey;

+ (NTSizeCalculatorTreeOperation*)treeOperation:(NTTreeOperationType)theType
									   delegate:(NSObject<NTOperationDelegateProtocol>*)theDelegate 
										   treeRoot:(NTSizeCalculatorTreeRoot*)theTreeRoot
										   data:(id)theData; // data depends on the type

@end
