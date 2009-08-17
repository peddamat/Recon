/* MyTerminalView */

#import <Cocoa/Cocoa.h>

@interface MyTerminalView : NSView
{
}

- (void)refreshWindow;
- (void)addNewTabWithCommand:(NSString *)command;
- (void)sendStringToCurrentTab:(NSString *)string;
@end
