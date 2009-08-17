//
//  NTModulePluginProtocol.h
//

#import <Cocoa/Cocoa.h>
#import "NTPathFinderPluginHostProtocol.h"

// built in standard module plugins
#define kNTPluginIdentifier_preview @"com.cocoatech.PathFinder.PreviewModulePlugin"
#define kNTPluginIdentifier_permissions @"com.cocoatech.PathFinder.PermissionsModulePlugin"
#define kNTPluginIdentifier_attribute @"com.cocoatech.PathFinder.AttributeModulePlugin"
#define kNTPluginIdentifier_size @"com.cocoatech.PathFinder.SizeModulePlugin"
#define kNTPluginIdentifier_info @"com.cocoatech.PathFinder.InfoModulePlugin"
#define kNTPluginIdentifier_openWith @"com.cocoatech.PathFinder.OpenWithModulePlugin"
#define kNTPluginIdentifier_subversion @"com.cocoatech.PathFinder.SVNModulePlugin"
#define kNTPluginIdentifier_console @"com.cocoatech.PathFinder.ConsoleModulePlugin"
#define kNTPluginIdentifier_sourceList @"com.cocoatech.PathFinder.SourceListModulePlugin"
#define kNTPluginIdentifier_coverFlow @"com.cocoatech.PathFinder.CoverflowModulePlugin"
#define kNTPluginIdentifier_processes @"com.cocoatech.PathFinder.ProcessesModulePlugin"

typedef enum
{
	kSelectionUpdated_browserEvent = 1 << 0,
	kContainingDirectoryUpdated_browserEvent = 1 << 1,
	kModuleWasHidden_browserEvent = 1 << 2,
	kDisplayedItemsUpdated_browserEvent = 1 << 3,
} NTBrowserEventType;

// ==============================================================================================
// required protocol, you must implement this protocol in your principle class

@protocol NTModulePluginProtocol <NSObject>

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;

- (NSView*)view;
- (NSMenu*)menu;

// an event occurred
- (void)browserEvent:(NTBrowserEventType)event browserID:(NSString*)theBrowserID;

@end
