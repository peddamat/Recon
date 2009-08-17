
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface NTIconFamily : NSObject
{
    IconFamilyHandle mIconFamilyHandle;
}

+ (NTIconFamily*)iconFamilyWithIconOfFile:(NTFileDesc*)desc;
+ (NTIconFamily*)iconFamilyWithImage:(NSImage*)image;
+ (NTIconFamily*)iconFamilyWithHandle:(IconFamilyHandle)handle;

- (IconFamilyHandle)iconFamilyHandle;

- (BOOL)writeToFile:(NSString*)path;

- (NSImage*)image;

- (BOOL) setAsCustomIconForFile:(NTFileDesc*)desc;
- (BOOL) setAsCustomIconForDirectory:(NTFileDesc*)desc;

+ (BOOL) removeCustomIconFromFile:(NTFileDesc*)desc;
+ (BOOL) removeCustomIconFromDirectory:(NTFileDesc*)desc;

+ (BOOL) hasCustomIconForFile:(NTFileDesc*)desc;
+ (BOOL) hasCustomIconForDirectory:(NTFileDesc*)desc;

// force the OS to recompute the icon for this path.  Used when duplicating an application
+ (void)updateIconRef:(NTFileDesc*)desc;

@end

// Methods for interfacing with the Carbon Scrap Manager (analogous to and
// interoperable with the Cocoa Pasteboard).
@interface NTIconFamily (ScrapAdditions)
+ (BOOL)canInitWithPasteboard;
+ (NTIconFamily*)iconFamilyWithPasteboard;
- (void)putOnPasteboard;
@end
