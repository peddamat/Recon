//
//  NTMenuPluginProtocol.h
//

#import <Cocoa/Cocoa.h>
#import "NTPathFinderPluginHostProtocol.h"
#import "NTPluginConstants.h"

// built in standard menu plugins
#define kNTPluginIdentifier_imageEditor @"com.cocoatech.ImageEditorMenuPlugin"
#define kNTPluginIdentifier_hexView @"com.cocoatech.PathFinder.HexView"
#define kNTPluginIdentifier_diskImage @"com.cocoatech.PathFinder.DiskImage"
#define kNTPluginIdentifier_screenCapture @"com.cocoatech.PathFinder.ScreenCaptureMenuPlugin"
#define kNTPluginIdentifier_burnMenu @"com.cocoatech.BurnMenuPlugin"
#define kNTPluginIdentifier_imageSizeMenu @"com.cocoatech.PathFinder.ImageSizeMenuPlugin"
#define kNTPluginIdentifier_quickLookMenu @"com.cocoatech.QuickLookMenuPlugin"

// ==============================================================================================
// required formal protocol, you must implement this protocol in your principle class

@protocol NTMenuPluginProtocol <NSObject>

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;

// return an NSMenuItem to be used in the plugins menu.  You can add a submenu to this item if you need more menu choices
// be sure to implement - (BOOL)validateMenuItem:(NSMenuItem*)menuItem; in your menuItems target to enable/disable the menuItem
- (NSMenuItem*)menuItem;
- (NSMenuItem*)contextualMenuItem;

// act directly on these items, not the current selection
- (id)processItems:(NSArray*)items parameter:(id)parameter;
@end

