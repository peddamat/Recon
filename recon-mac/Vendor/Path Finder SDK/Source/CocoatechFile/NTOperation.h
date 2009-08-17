//
//  NTOperation.h
//  CocoatechFile
//
//  Created by Steve Gehrman on 1/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTOperation;

@protocol NTOperationDelegateProtocol <NSObject>
// called on main thread
- (void)operation_complete:(NTOperation*)operation;
@end

@interface NTOperation : NSOperation
{
	NSObject<NTOperationDelegateProtocol>* delegate; // not retained
	id parameter;
	id result;
}
@property (assign) NSObject<NTOperationDelegateProtocol>* delegate;
@property (retain) id parameter;
@property (retain) id result;

+ (NTOperation*)operation:(NSObject<NTOperationDelegateProtocol>*)theDelegate
				parameter:(id)theParameter;

- (void)clearDelegate;

// called by client to signal the delegate that we are done
- (void)operationDone;

@end
