#import "ManagingViewController.h"

@implementation ManagingViewController

@synthesize managedObjectContext;
@synthesize sessionsArrayController;
@synthesize profilesArrayController;

@synthesize notesInHostArrayController;
@synthesize hostsInSessionArrayController;

@synthesize workspacePlaceholder; 

- (void)dealloc
{
   [managedObjectContext release];
   [sessionsArrayController release];
   [profilesArrayController release];  
   [notesInHostArrayController release];
   [hostsInSessionArrayController release];
   
   [workspacePlaceholder release];
   
   [super dealloc];
}

- (void)keyDown:(NSEvent *)anEvent
{
//	unsigned int modflag = [anEvent modifierFlags];
//   unsigned short keycode = [anEvent keyCode];
//      
//	if ([anEvent type] == NSKeyDown)
//   {
//      if ((modflag & NSCommandKeyMask) && (keycode == 37))
//         [NSApp sendAction:@selector(focusInputField:) to:nil from:self];
//      else if ((modflag & NSCommandKeyMask) && (keycode == 3))
//         [NSApp sendAction:@selector(zoom:) to:nil from:self];
//   }
}

@end
