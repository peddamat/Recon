

A module plugin will allow you to add a view to Path Finder's main browser window and it sends you events for example when the selection changes.  
This allows you to write a file preview, or a panel that could execute commands on the selection.  The possibilities are endless.

Writing a plugin is simple.  There are only a few steps:

- Create a new Cocoa bundle project in XCode
- Add a principle class that conforms to a protocol
- Write code to build the menu item and actions that implement to the menu's commands
- Set the bundle's identifier to something unique
- Drop it in the ~/Library/Application Support/Path Finder/PlugIns
- Relaunch Path Finder

// ================================
// Tutorial
// ================================

Here's a step by step tutorial to create a simple module plugin.

Launch XCode. Create new project. Choose the "Cocoa Bundle" project template.

Click on Info.plist and paste this somewhere:

	<key>NTPluginBundleInfoKey_type</key>
	<string>MODULE_PLUGIN</string>

Optionally add a minimum OS version
	<key>LSMinimumSystemVersion</key>
	<string>10.5</string>

When Path Finder loads the plugin, it looks at this key to determine the plugin type.

Now set a unique bundle identifier, bundle name and bundle extension:
- Click on the Target in XCode, choose Get Info
- Click the "Properties" tab
- The default identifier is "com.yourcompany.yourcocoabundle", change it to something that makes sense like "com.acmePluginCo.coolMenuCommand"
- Click the "General" tab
- Change the Name at top to something that makes sense
- Click the "Build" tab
- Change the "Wrapper Extension" from "bundle" to "plugin" for all configurations
- Paste next line for all configurations so it can locate the .h files in the SDK.  This assumes your project folder is in the same folder as the SDK.
HEADER_SEARCH_PATHS = ../../CocoatechProtocols/

You should also consider localizing the bundle name since this is what is displayed
in the UI for customizing the contextual menu. Create a InfoPlist.string files for the localization you want to support, and add a line similar to:

CFBundleName = "Localized Command Name";

Implement principle class.  The principle class must implement the NTModulePluginProtocol protocol.  This protocol can be found in NTModulePluginProtocol.h in the SDK folder.

- Create a new Objective-C file in XCode.  I'll name mine NTModulePluginTutorial.m for this tutorial.
- Set the principle class to the name of your object in the "Properties" tab of the target.

In the .h file created, add the <NTModulePluginProtocol> after NSObject since we must implement this protocol.

#import "NTModulePluginProtocol.h"

@interface NTModulePluginTutorial : NSObject <NTModulePluginProtocol> {
}
@end

Here's a bare bones implementation of the protocol for the .m file:

@implementation NTModulePluginTutorial

+ (id)plugin:(id<NTPathFinderPluginHostProtocol>)host;
{
    id result = [[self alloc] init];
	
	// you would normally want to retain the host to communicate with the application, but for this simple example we don't
	// [self setHost:host];
			
    return [result autorelease];
}

- (NSMenuItem*)contextualMenuItem;
{
	return [self menuItem];
}

- (NSMenuItem*)menuItem;
{
    NSMenuItem* menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Beep" keyEquivalent:@""] autorelease];
    [menuItem setAction:@selector(pluginAction:)];
    [menuItem setTarget:self];

    return menuItem;
}

- (void)pluginAction:(id)sender;
{
    // just beep, not very useful
	NSBeep();
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;
{
    return YES;
}

// act directly on these items, not the current selection
- (id)processItems:(NSArray*)items parameter:(id)parameter;
{
    // do nothing
	return nil;	
}

@end

Copying resulting built plugin to: ~/Library/Application Support/Path Finder/PlugIns/

Relaunch Path Finder to load this new plugin.  The plugin will append a menu item with the title "Beep".  
If you open the preferences panel for customizing the contextual menu, you will see an item listed using the bundle name.

That's all there is too it.  Now you just need to add your own code to do something useful.

// ================================
// Plugin Host
// ================================

In the tutorial above, I mention that you can retain the host to be able to communicate with Path Finder.  Look at the header file named NTPathFinderPluginHostProtocol.h

It's pretty self explanatory.  It has a bunch of methods for doing things like copying/moving/trashing files, launching command line tools, getting the current selection, opening text documents, getting the current directory etc.  The sample plugins included in the SDK all use the host for something, so look there if your confused.

// ================================
// Theme colors
// ================================

If you open NTWindowThemeSupport.h you will see a category on NSApplication that adds a simple global way of getting the current windows default theme color.  This is useful if you want your colors to match the rest of the browser window.

It's really simple.  Here's some sample code:

{
  NSDictionary *theme = [NSApp themeForWindow:[self window]];  // ask application what colors I need to use for my window
  NSColor *color = [NSColor whiteColor];

  if (theme)
    color = [theme objectForKey:kNTThemeBackgroundColor];

  [color set];
  ...
}

// ================================
// Plugin Ideas
// ================================

ACL editor
MP3 tag editor
FTP client
Hex editor
Text editor
Recent applications
Batch renamer
Image resizer
Image editor



