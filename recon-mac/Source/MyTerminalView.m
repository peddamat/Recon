#import "MyTerminalView.h"
#import <CocoatechCore/NTCoreMacros.h>
#import <iTerm/iTermController.h>
#import <iTerm/ITAddressBookMgr.h>
#import <iTerm/ITTerminalView.h>


@implementation MyTerminalView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
	}
	return self;
}

//- (void)drawRect:(NSRect)rect
//{
//   
//}

- (void)awakeFromNib;
{
	// make sure this is initialized (yes goofy, I know)
 	[iTermController sharedInstance];
	
	NSDictionary* dict = [[ITAddressBookMgr sharedInstance] defaultBookmarkData];
	ITTerminalView* term = [ITTerminalView view:dict];
   
	[term setFrame:[self bounds]];
	
	[self addSubview:term];
	[term addNewSession:dict withCommand:nil withURL:nil];
   
   [term setUseTransparency:YES];
//   PTYSession *currentSession = [term currentSession];
//   [term setupSession:currentSession title:@"Test"];   

	// goofy hack to show window, ignore
//	[self performSelector:@selector(showWindow) withObject:nil afterDelay:0];
}

- (void)showWindow;
{
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)refreshWindow
{
	ITTerminalView* term = [[self subviews] lastObject];
   [term setWindowSize];
}

- (void)addNewTabWithCommand:(NSString *)command
{
	NSDictionary* dict = [[ITAddressBookMgr sharedInstance] defaultBookmarkData];   
	ITTerminalView* term = [[self subviews] lastObject];

	[term addNewSession:dict withCommand:nil withURL:nil];
   [term runCommand:command];
}

- (void)sendStringToCurrentTab:(NSString *)string
{
	NSDictionary* dict = [[ITAddressBookMgr sharedInstance] defaultBookmarkData];   
	ITTerminalView* term = [[self subviews] lastObject];

   PTYSession *currentSession = [term currentSession];
   [currentSession insertText:string];
}



@end
