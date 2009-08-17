

A menu plugin will allow you to add commands to Path Finder's menu bar and contextual menu.

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

Here's a step by step tutorial to create a simple menu plugin.

Launch XCode. Create new project. Choose the "Cocoa Bundle" project template.

Click on Info.plist and paste this somewhere:

	<key>NTPluginBundleInfoKey_type</key>
	<string>MENU_PLUGIN</string>

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
- Paste next line for all configurations so it can locate the .h files in the SDK
HEADER_SEARCH_PATHS = ../../CocoatechProtocols/

You should also consider localizing the bundle name since this is what is displayed
in the UI for customizing the contextual menu. Create a InfoPlist.string files for the localization you want to support, and add a line similar to:

CFBundleName = "Localized Command Name";

Implement principle class.  The principle class must implement the NTMenuPluginProtocol protocol.  This protocol can be found in NTMenuPluginProtocol.h in the SDK folder.

- Create a new Objective-C file in XCode.  I'll name mine NTMenuPluginTutorial.m for this tutorial.
- Set the principle class in the "Properties" tab of the target.

In the .h file created, add the <NTMenuPluginProtocol> after NSObject since we must implement this protocol.

#import "NTMenuPluginProtocol.h"

@interface NTMenuPluginTutorial : NSObject <NTMenuPluginProtocol> {
}
@end

Here's a bare bones implementation of the protocol for the .m file:

@implementation NTMenuPluginTutorial

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



