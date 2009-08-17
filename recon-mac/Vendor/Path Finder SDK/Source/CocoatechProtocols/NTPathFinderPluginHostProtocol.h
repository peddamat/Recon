//
//  NTPathFinderFilePluginHostProtocol.h
//

#import <Cocoa/Cocoa.h>
#import "NTPluginConstants.h"
#import "NTFSItemProtocol.h"

typedef enum NTModuleInstallLocation
{
	kUndefined_moduleLocation=0,
	
	kInfoWindow_moduleLocation,
	kInfoInspector_moduleLocation,
	kBrowser_moduleLocation,
	kInspector_moduleLocation,
} NTModuleInstallLocation;

// ==============================================================================================
// pluginHost protocol - this is the protocol the plugin uses to control the host application

// file objects are represented with id<NTFSItem>, if you need a path or URL, you can [item path] etc.
// I did this so you could write a plugin without linking to any additional code
// the pluginHost has methods to create these from paths

@protocol NTPathFinderPluginHostProtocol <NSObject>

- (unsigned)version;  // 4.6.2 will return 462

// create an NTFSItem with a path
- (id<NTFSItem>)newFSItem:(NSString*)path;
- (NSArray*)newFSItems:(NSArray*)paths;

- (NSWindow*)sheetWindow:(NSWindow*)window;

// parameters, defined by plugin
- (NSDictionary*)pluginParameters;

- (void)revealItem:(id<NTFSItem>)item window:(NSWindow*)theWindow browserID:(NSString*)theBrowserID;

// opens folder, files or applications
- (void)openItems:(NSArray*)items window:(NSWindow*)theWindow browserID:(NSString*)theBrowserID;

// rename a file or folder
- (void)rename:(id<NTFSItem>)item withName:(NSString*)newName;

// calls runTool_result:(NSDictionary*)results when done, compare to returned pluginID and do something with results
- (NSNumber*)runTool:(NSString*)tool 
		   directory:(NSURL*)directory
		   arguments:(NSArray*)arguments 
			  target:(id)target
			  setUID:(BOOL)setUID;

// context must include a @"target" key with an object that responds to:
// - (void)askUser_response:(BOOL)canceled context:(NSDictionary*)context;
- (void)askUser:(NSString*)title
		message:(NSString*)message
	   okButton:(NSString*)OKButton
   cancelButton:(NSString*)cancelButton
		 window:(NSWindow*)window
		context:(NSDictionary*)context;

// localizes using CocoatechStrings framework
- (NSString*)localize:(NSString*)localize table:(NSString*)table;

// ================================================
// selection
// ================================================

- (NSArray*)selection:(NSWindow*)window browserID:(NSString*)theBrowserID;

// select an item - item must be in the current directory or it doesn't do anything
- (void)selectItems:(NSArray*)items byExtendingSelection:(BOOL)byExtendingSelection inWindow:(NSWindow*)window browserID:(NSString*)theBrowserID;

// returns the current directory of the frontmost document
- (id<NTFSItem>)currentDirectory:(NSWindow*)window browserID:(NSString*)theBrowserID;
- (void)setCurrentDirectory:(id<NTFSItem>)directory inWindow:(NSWindow*)window browserID:(NSString*)theBrowserID;

// current search file if displaying search
- (id<NTFSItem>)savedSearchFile:(NSWindow*)window browserID:(NSString*)theBrowserID;

// ================================================
// displayed items
// ================================================

// displayed items
- (NSArray*)displayedItems:(NSWindow*)window browserID:(NSString*)theBrowserID;

// on screen rect of items icon in screen coordinates (used for zoom effects)
- (NSRect)frameForItem:(id<NTFSItem>)item window:(NSWindow*)window browserID:(NSString*)theBrowserID;

// ================================================
// windows
// ================================================

// create a text editor window with a string (just like the built in reports feature)
// string can be an NSAttributedString or NSString
- (void)textDocumentWithString:(id)string;
- (void)openTerminal:(id<NTFSItem>)item;

- (void)showGetInfoWindows:(NSArray*)items;

// textual report of all files attributes
- (void)reportForItems:(NSArray*)items;

// ================================================
// moving, copying, trashing
// ================================================

// move an item from one directory to another
- (void)moveItems:(NSArray*)items toDirectory:(id<NTFSItem>)directory;

// copy an item from one directory to another
- (void)copyItems:(NSArray*)items toDirectory:(id<NTFSItem>)directory;

//  move an item to the trash can
- (void)trashItems:(NSArray*)items;

// ================================================
// set file attributes
// ================================================

// pass an NSNumber for Bool for attributes, NSDate for dates, NSString for type/creator
- (void)set:(id)value attributeID:(NTFileAttributeID)attributeID items:(NSArray*)items;
- (void)toggleAttributeID:(NTFileAttributeID)attributeID items:(NSArray*)items;

- (void)applyDirectoriesAttributesToContents:(id<NTFSItem>)directory;

// call another menu plugin to process items (get info, image converter, hex, etc)
- (id)processItems:(NSArray*)item
		 parameter:(id)parameter 
		  pluginID:(NSString*)pluginID;

// set to YES if the menuPlugin wants to get processItems called everytime selection changes
- (BOOL)updateMenuPluginForEvents;
- (void)setUpdateMenuPluginForEvents:(BOOL)flag;

// convenience method for getting OS icons.  See Icons.h for constants (kBurningIcon for example)
- (NSImage*)iconForType:(OSType)type size:(int)size;
- (NSImage*)imageWithName:(NSString*)name;  // images in CoreTypes.bundle

// ================================================
// module install location information
// ================================================

- (NTModuleInstallLocation)moduleLocation;    // module install location (doesn't apply to menu plugins)
- (NSString*)modulePrefKey;                   // same module could be installed in different locations, append this key for all your pref keys
- (BOOL)inspectorModule;                      // module can behave differently if it's installed in an inspector,  
- (BOOL)infoModule;                           // the get info window or info inspector

- (NSString*)syncToBrowserID;

@end

// the host calls your plugin if you implement these
@interface NSObject (HostInformalProtocol)
- (void)askUser_response:(BOOL)canceled context:(NSDictionary*)context;
- (void)runTool_result:(NSDictionary*)context;
@end

