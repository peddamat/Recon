//
//  NTSizeUIController.m
//  SizeModulePlugin
//
//  Created by Steve Gehrman on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NTSizeUIController.h"
#import "NTSizeUIModel.h"
#import "NTSizeUIModelThread.h"

@interface NTSizeUIController (hidden)
- (void)setView:(NSView *)theView;
@end

@interface NTSizeUIController (Private)
- (void)layoutSubviews;
- (NSView*)createView;

- (void)updateProgressIndicator:(BOOL)show;

- (NTThreadRunner *)threadRunner;
- (void)setThreadRunner:(NTThreadRunner *)theThreadRunner;

- (NTListSizeCalculator *)sizeCalculator;
- (void)setSizeCalculator:(NTListSizeCalculator *)theSizeCalculator;

- (NSProgressIndicator *)progressIndicator;
- (void)setProgressIndicator:(NSProgressIndicator *)theProgressIndicator;
@end

@interface NTSizeUIController (Protocols) <NTThreadRunnerDelegateProtocol, NTListSizeCalculatorDelegateProtocol>
@end

@implementation NTSizeUIController

@synthesize sizeTextField;
@synthesize nameTextField;
@synthesize attributesTextField;
@synthesize iconView, contentView, model, host, objectController;

+ (NTSizeUIController*)controller:(id<NTPathFinderPluginHostProtocol>)host;
{
	NTSizeUIController* result = [[NTSizeUIController alloc] init];
	
	[result setHost:host];
	
	// load the prefs panel  nib
	if (![NSBundle loadNibNamed:@"UI" owner:result])
	{
		NSLog(@"Failed to load UI.nib");
		NSBeep();
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:result selector:@selector(frameDidChangeNotification:) name:NSViewFrameDidChangeNotification object:result.contentView];
	
	return [result autorelease];
}

- (void)frameDidChangeNotification:(NSNotification*)theNotification;
{
	[self layoutSubviews];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    [self setView:nil];
	[self setThreadRunner:nil];
    [self setSizeCalculator:nil];
    [self setProgressIndicator:nil];
	
	[self.objectController release]; // top level nib object
	self.objectController = nil;
	[self.contentView release]; // top level nib object
	self.contentView = nil;
	
	self.model = nil;
	self.sizeTextField = nil;
    self.nameTextField = nil;
    self.attributesTextField = nil;
    self.iconView = nil;
	
    [super dealloc];
}

//---------------------------------------------------------- 
//  view 
//---------------------------------------------------------- 
- (NSView *)view
{
	if (!mView)
		[self setView:[self createView]];

    return mView; 
}

- (void)setView:(NSView *)theView
{
    if (mView != theView)
    {
        [mView release];
        mView = [theView retain];
    }
}

- (void)invalidate; // called so we can be dealloced, retained by objectController
{
	[[self objectController] unbind:@"contentObject"];
}

- (void)selectionUpdated:(NSArray*)items;
{
	// kill any running threads
	[self setThreadRunner:nil];
	[self setSizeCalculator:nil];
	[self updateProgressIndicator:NO];

	if (![items count])
		items = nil;
	
	if (items)
	{
		// start thread
		[self setThreadRunner:[NTSizeUIModelThread thread:items delegate:self]];
	}
	else
		[self setModel:nil];	
}

@end

@implementation NTSizeUIController (Protocols)

// NTThreadRunnerDelegateProtocol
- (void)threadRunner_complete:(NTThreadRunner*)threadRunner;
{
	if (threadRunner == [self threadRunner])
	{
		NTSizeUIModelThread* param = (NTSizeUIModelThread*)[threadRunner param];
				
		// set our new model
		[self setModel:[param model]];
		
		// if only one file selected, add the desc to the icon view so it can be edited
		[self.iconView setDesc:nil]; // clear out any old value
		if ([[param descs] count])
			[self.iconView setDesc:[[param descs] objectAtIndex:0]];

		// clear the thread, it's done
		[self setThreadRunner:nil];
		
		// now start size thread if size is nil
		if (![[self model] size])
		{
			[self updateProgressIndicator:YES];  // this will show the progress indicator
			
			if ([[param descs] count])
				[self setSizeCalculator:[NTListSizeCalculator calculator:[param descs] delegate:self]];
		}
		
		[self layoutSubviews];
	}
}

// NTListSizeCalculatorDelegateProtocol
- (void)listSizeCalculatorUpdated:(NTListSizeCalculator*)sizeCalculator;
{
	if (sizeCalculator == [self sizeCalculator])
	{				
		[[self model] setSize:[[NTSizeFormatter sharedInstance] fileSize:[[sizeCalculator sizeSpec] physicalSize] allowBytes:NO]];
		[[self model] setSizeToolTip:[[NTSizeFormatter sharedInstance] fileSizeInBytes:[[sizeCalculator sizeSpec] physicalSize]]];
		
		[self updateProgressIndicator:NO];  // this will show the progress indicator
		[self layoutSubviews];
	}
}

@end

@implementation NTSizeUIController (Private)

- (void)layoutSubviews;
{
	NSRect bounds = [self.contentView bounds];
	const int kMargin = 3;
	
	NSRect iconRect, nameRect, attributesRect, sizeRect;
	
	// icon rect
	iconRect = [self.iconView frame];
	iconRect.origin.x = NSMinX(bounds) + kMargin;
	iconRect.origin.y = NSMaxY(bounds) - (NSHeight(iconRect) + kMargin);
	
	// size rect
	if ([self progressIndicator])
	{
		sizeRect = [[self progressIndicator] frame];
		sizeRect.origin.x = NSMaxX(bounds) - (NSWidth(sizeRect) + kMargin);
		sizeRect.origin.y = NSMaxY(bounds) - (NSHeight(sizeRect) + (kMargin*2));
	}
	else
	{
		[self.sizeTextField sizeToFit];

		sizeRect = [self.sizeTextField frame];
		sizeRect.origin.x = NSMaxX(bounds) - (NSWidth(sizeRect) + kMargin);
		sizeRect.origin.y = NSMaxY(bounds) - (NSHeight(sizeRect) + (kMargin*2));
	}
	
	// name rect
	nameRect = [self.nameTextField frame];
	nameRect.origin.x = NSMaxX(iconRect) + kMargin;
	nameRect.size.width = NSMinX(sizeRect) - NSMinX(nameRect);
	nameRect.origin.y = NSMaxY(bounds) - (NSHeight(nameRect) + (kMargin*2));
	
	// attributes rect
	attributesRect = [self.attributesTextField frame];
	attributesRect.origin.x = NSMaxX(iconRect) + kMargin;
	attributesRect.origin.y = NSMinY(nameRect) - (NSHeight(attributesRect) + kMargin);
	attributesRect.size.width = NSMaxX(bounds) - NSMinX(attributesRect);
	attributesRect.size.width -= kMargin;
	
	// set frame
	[self.nameTextField setFrame:nameRect];
	[self.attributesTextField setFrame:attributesRect];
	[self.iconView setFrame:iconRect];
	[self.sizeTextField setFrame:sizeRect];
	[[self progressIndicator] setFrame:sizeRect];
}

- (void)showProgressIndicatorAfterDelay;
{
	NSProgressIndicator* indicator = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0,0,10,10)] autorelease];
	[indicator setControlSize:NSSmallControlSize];
	[indicator setStyle:NSProgressIndicatorSpinningStyle];
	[indicator setUsesThreadedAnimation:YES];
	[indicator sizeToFit];
		
	[[self sizeTextField] setHidden:YES];

	[self setProgressIndicator:indicator];
	
	[self layoutSubviews];
	
	[[[self sizeTextField] superview] addSubview:indicator];
}

- (void)updateProgressIndicator:(BOOL)show;
{
	SEL sel = @selector(showProgressIndicatorAfterDelay);
	
	// cancel any delayed calls
	[self safeCancelPreviousPerformRequestsWithSelector:sel object:nil];
	
	if (show)
	{
		if (![self progressIndicator])
			[self performDelayedSelector:sel withObject:nil delay:.5];
	}
	else
	{
		if ([self progressIndicator])
		{
			[[self progressIndicator] removeFromSuperviewWithoutNeedingDisplay];
			[[self sizeTextField] setHidden:NO];
			
			// don't need it anymore
			[self setProgressIndicator:nil];
			
			[self layoutSubviews];
		}
	}
}

//---------------------------------------------------------- 
//  progressIndicator 
//---------------------------------------------------------- 
- (NSProgressIndicator *)progressIndicator
{	
    return mProgressIndicator; 
}

- (void)setProgressIndicator:(NSProgressIndicator *)theProgressIndicator
{
    if (mProgressIndicator != theProgressIndicator)
    {
		[mProgressIndicator stopAnimation:nil];

        [mProgressIndicator release];
        mProgressIndicator = [theProgressIndicator retain];
		
		[mProgressIndicator startAnimation:nil];
	}
}

//---------------------------------------------------------- 
//  threadRunner 
//---------------------------------------------------------- 
- (NTThreadRunner *)threadRunner
{
	return mThreadRunner; 
}

- (void)setThreadRunner:(NTThreadRunner *)theThreadRunner
{
	if (mThreadRunner != theThreadRunner) {
		[mThreadRunner clearDelegate];
		
		[mThreadRunner release];
		mThreadRunner = [theThreadRunner retain];
	}
}

//---------------------------------------------------------- 
//  sizeCalculator 
//---------------------------------------------------------- 
- (NTListSizeCalculator *)sizeCalculator
{
    return mSizeCalculator; 
}

- (void)setSizeCalculator:(NTListSizeCalculator *)theSizeCalculator
{
    if (mSizeCalculator != theSizeCalculator)
    {
		[mSizeCalculator clearDelegate];

        [mSizeCalculator release];
        mSizeCalculator = [theSizeCalculator retain];
    }
}

- (NSView*)createView;
{
	// make transparent
	if (![[self host] infoModule])
		[(id)[self contentView] setDrawsBackground:YES];
	
	return [self contentView];
}

@end
