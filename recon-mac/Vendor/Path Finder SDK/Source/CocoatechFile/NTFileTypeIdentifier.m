//
//  NTFileTypeIdentifier.m
//  CocoatechFile
//
//  Created by sgehrman on Sun Sep 23 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTFileTypeIdentifier.h"
#import <QuickTime/QuickTime.h>
#import <QuickTime/Movies.h>
#import "NTWeblocFile.h"
#import "NTImageTypeMgr.h"

@implementation NTFileTypeIdentifier

- (id)initWithDesc:(NTFileDesc*)desc;
{
    self = [super init];

    _desc = desc; // don't retain!

    return self;
}

+ (id)typeIdentifier:(NTFileDesc*)descEntry;
{
    NTFileTypeIdentifier* result = [[NTFileTypeIdentifier alloc] initWithDesc:descEntry];

    return [result autorelease];
}

- (void)dealloc;
{
	_desc = nil;
	
    [super dealloc];
}

- (BOOL)isImage;
{
    if (!_flags._isImage_initialized)
    {
        BOOL result = NO;

        if (_desc && [_desc isFile] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];
            
            result = [[NTImageTypeMgr sharedInstance] isImageExtension:ext];
            if (!result)
            {
                int type = [_desc type];
                
                result = [[NTImageTypeMgr sharedInstance] isImageHFSType:type];
                if (!result)
                {
                    // check for adobe illustrator
                    result = ([ext isEqualToStringCaseInsensitive:@"ai"]);
                    if (!result)
                    {
                        int creator = [_desc creator];
                        
                        // ART5 == Illustrator, ext = ".ai"
                        result = (creator == 'ART5' && type == 'TEXT');
                        
                        if (!result)
                            result = ([ext isEqualToStringCaseInsensitive:@"PCD"]);  // Photo CD
                    }
                }
            }
        }

        _flags._isImage = (result) ? 1:0;
        _flags._isImage_initialized = 1;
    }
	
    return (_flags._isImage == 1);
}

- (BOOL)isBinaryPList;  // .plist or .strings (iphone)
{
	if (!_flags._isBinaryPList_initialized)
    {
		BOOL result = NO;
		
		if (_desc && [_desc isFile] && ![_desc isAlias])
		{
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], (CFStringRef)@"com.apple.property-list");  // .plist file
			
			if (!result)
				result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], (CFStringRef)@"com.apple.xcode.strings-text");  // .strings file

			if (result)
			{
				// now check for bplist in first few bytes of file
				result = NO;
				
				NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[_desc path]];
				NSData *data = [fileHandle readDataOfLength:8];
				[fileHandle closeFile];
				
				// open the executable and look for string "bplist00"
				if (data)
				{
					if ([data length] == 8)
					{
						NSString* temp = [NSString stringWithUTF8String:[data bytes] length:8];
						
						if ([temp isEqualToString:@"bplist00"])
							result = YES;
					}
				}
			}
		}
		
		_flags._isBinaryPList = (result) ? 1:0;
        _flags._isBinaryPList_initialized = 1;
	}
	
	return (_flags._isBinaryPList == 1);
}

- (BOOL)isText;
{
    if (!_flags._isText_initialized)
    {
        BOOL result = NO;

        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];

            result = (([ext isEqualToStringCaseInsensitive:@"txt"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"c"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"cp"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"cc"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"cpp"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"as"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"make"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"sql"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"m"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"ad"]) ||  // XML format
                      ([ext isEqualToStringCaseInsensitive:@"savedSearch"]) ||  // XML format
                      ([ext isEqualToStringCaseInsensitive:@"xcconfig"]) ||  // XCode config file, plain text
                      ([ext isEqualToStringCaseInsensitive:@"mm"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"php"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"sh"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"guess"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"in"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"am"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"xml"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"sdef"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"readme"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"rb"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"pl"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"plx"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"xsl"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"cgi"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"pm"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"pch"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"css"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"log"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"spec"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"lsm"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"postamble"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"preamble"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"csh"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"h"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"r"]) ||
                      
                      ([ext isEqualToStringCaseInsensitive:@"ics"]) || // iCal file
                      ([ext isEqualToStringCaseInsensitive:@"vcf"]) || // Address Book file
                      
                      ([ext isEqualToStringCaseInsensitive:@"java"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"plist"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"info"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"scriptTerminology"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"scriptSuite"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"suiteModel"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"status"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"strings"]) ||
                      ([ext isEqualToStringCaseInsensitive:@"applescript"]));

            if (!result)
            {
                // check type
                int type = [_desc type];
                int creator = [_desc creator];

                // if no type and no extension, check the file name (README or READ ME)
                if (type == 0 && ([ext length] == 0))
                {
                    // common unix text file names
                    result = (([[_desc name] isEqualToStringCaseInsensitive:@"README"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"READ ME"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"CONFIGURE"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"LICENSE"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"TODO"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"depcomp"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"NEWS"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"HISTORY"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"AUTHORS"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"EXTENSIONS"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"CODING_STANDARDS"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"CREDITS"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"COPYING"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"THANKS"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"MAKEFILE"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"INSTALL"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"CONTROL"]) ||
                              ([[_desc name] isEqualToStringCaseInsensitive:@"CHANGELOG"])
                              );
                }
                else
                {	
                    // Illustrator files have type text, there may be others to, so check if we're an image before testing the type 'TEXT'
                    if (![self isImage])
                        result = (type == 'TEXT');
					
					if (!result)
						result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypePlainText);
					if (!result)
						result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeUTF16PlainText);
					if (!result)
						result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeUTF8PlainText);
					
                    if (!result)
                        result = (type == 'ttro');
					
					// Smultron
					if (!result)
                        result = (type == 'SMLd' || creator == 'SMUL');

					// SDEF
					if (!result)
                        result = (type == 'Sdef' || creator == 'SdEd');
					
					// Entourage email file
					if (!result)
                        result = (type == 'M822' || creator == 'OPIM');
				}
            }
        }

        _flags._isText = (result) ? 1:0;
        _flags._isText_initialized = 1;
    }

    return (_flags._isText == 1);
}

- (BOOL)isMovie;
{
    if (!_flags._isMovie_initialized)
    {
        BOOL result = NO;
		
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
		{
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeMovie);
						
			if (!result)
				result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeVideo);
			
			if (!result)
			{
				NSString* ext = [_desc extension];
				
				// dv files - not sure why this doesn't work, but it doesn't
				result = ([ext isEqualToStringCaseInsensitive:@"dv"]);
				
				if (!result)
				{
					// had to check for this.  UTTypeConformsTo returning false, file had a name like xxx.mov 02, but Kind looked good, and quicktime opened it, default app OK
					result = ([_desc type] == 'dvc!'); // 'Hway' was creator (I think it's iMovie)
				}
			}						  
		}
		
        _flags._isMovie = (result) ? 1:0;
        _flags._isMovie_initialized = 1;
    }

    return (_flags._isMovie == 1);
}

- (BOOL)isAudio;
{
    if (!_flags._isAudio_initialized)
    {
        BOOL result = NO;
        
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
		{
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeAudio);
			
			// hack added because Audio CDs return the wrong UTI (Tiger)
			if (!result)
				result = [[_desc extension] isEqualToStringCaseInsensitive:@"aiff"];
        }
		
        _flags._isAudio = (result) ? 1:0;
        _flags._isAudio_initialized = 1;
    }
    
    return (_flags._isAudio == 1);
}

- (BOOL)isMP3;
{
    if (!_flags._isMP3_initialized)
    {
        BOOL result = NO;

		if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeMP3);

        _flags._isMP3 = (result) ? 1:0;
        _flags._isMP3_initialized = 1;
    }

    return (_flags._isMP3 == 1);
}

- (BOOL)isClassicSound;  // classic sound resource
{
    if (!_flags._isClassicSound_initialized)
    {
        BOOL result = NO;

        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
            // check type
            int type = [_desc type];
            int creator = [_desc creator];

            result = (type == 'sfil' && creator == 'movr');  // Finder sound file

            if (!result)
                result = (type == 'zsys' && creator == 'MACS');  // suitcase file (could have snd resources)
        }

        _flags._isClassicSound = (result) ? 1:0;
        _flags._isClassicSound_initialized = 1;
    }

    return (_flags._isClassicSound == 1);
}

- (BOOL)isMSWord;
{
    if (!_flags._isMSWord_initialized)
    {
        BOOL result = NO;
        
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];
            
            result = ([ext isEqualToStringCaseInsensitive:@"doc"]);
            
            if (!result)
            {
                // check type
                int type = [_desc type];
                result = (type == 'W8BN' || type == 'W6BN');
            }
        }
        
        _flags._isMSWord = (result) ? 1:0;
        _flags._isMSWord_initialized = 1;
    }
    
    return (_flags._isMSWord == 1);
}

- (BOOL)isRTF;
{
    if (!_flags._isRTF_initialized)
    {
        BOOL result = NO;
        
		if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeRTF);
        
        _flags._isRTF = (result) ? 1:0;
        _flags._isRTF_initialized = 1;
    }
    
    return (_flags._isRTF == 1);
}

- (BOOL)isRTFD;
{
    if (!_flags._isRTFD_initialized)
    {
        BOOL result = NO;

        // rtfds are directories, are they packages too?
		if (_desc && [_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeRTFD);

        _flags._isRTFD = (result) ? 1:0;
        _flags._isRTFD_initialized = 1;
    }

    return (_flags._isRTFD == 1);
}

- (BOOL)isZip;
{
    if (!_flags._isZip_initialized)
    {
        BOOL result = NO;
        
		if (_desc && ![_desc isDirectory] && ![_desc isAlias])
		{
			NSString* ext = [_desc extension];
			result = ([ext isEqualToStringCaseInsensitive:@"zip"]);
        }
		
        _flags._isZip = (result) ? 1:0;
        _flags._isZip_initialized = 1;
    }
    
    return (_flags._isZip == 1);
}

- (BOOL)isHTML;
{
    if (!_flags._isHTML_initialized)
    {
        BOOL result = NO;
        
		if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeHTML);
        
        _flags._isHTML = (result) ? 1:0;
        _flags._isHTML_initialized = 1;
    }
    
    return (_flags._isHTML == 1);
}

- (BOOL)isChat;
{
    if (!_flags._isChat_initialized)
    {
        BOOL result = NO;
        
		if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], CFSTR("com.apple.ichat.transcript"));
		
		if (result)
		{
			// filter out ._ files
			if ([[_desc name] hasPrefix:@"._"])
				result = NO;
		}
		
        _flags._isChat = (result) ? 1:0;
        _flags._isChat_initialized = 1;
    }
    
    return (_flags._isChat == 1);
}

- (BOOL)isFlashVideo;
{
	if (!_flags._isFlashVideo_initialized)
    {
        BOOL result = NO;
        
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
			NSString* ext = [_desc extension];
			
			result = ([ext isEqualToStringCaseInsensitive:@"flv"]); // flash file (web kit plays them)
        }
        
        _flags._isFlashVideo = (result) ? 1:0;
        _flags._isFlashVideo_initialized = 1;
    }
    
    return (_flags._isFlashVideo == 1);	
}

- (BOOL)isFlash;
{
	if (!_flags._isFlash_initialized)
    {
        BOOL result = NO;
        
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
			NSString* ext = [_desc extension];
			
			result = ([ext isEqualToStringCaseInsensitive:@"swf"]); // flash file (web kit plays them)
        }
        
        _flags._isFlash = (result) ? 1:0;
        _flags._isFlash_initialized = 1;
    }
    
    return (_flags._isFlash == 1);	
}

- (BOOL)isWebArchive;
{
	if (!_flags._isWebArchive_initialized)
    {
        BOOL result = NO;
        
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
			NSString* ext = [_desc extension];
			
			result = ([ext isEqualToStringCaseInsensitive:@"webarchive"]); // Safari saves html pages with images as .webarchive
        }
        
        _flags._isWebArchive = (result) ? 1:0;
        _flags._isWebArchive_initialized = 1;
    }
    
    return (_flags._isWebArchive == 1);	
}


- (BOOL)isWeb;
{
    if (!_flags._isWeb_initialized)
    {
        BOOL result = NO;
        
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
            if ([self isHTML] || [self isFlashVideo] || [self isFlash])
                result = YES;
			else
            {
                NSString* ext = [_desc extension];
                
                result = ([ext isEqualToStringCaseInsensitive:@"asp"] ||
						  [ext isEqualToStringCaseInsensitive:@"svg"] || 
                          [ext isEqualToStringCaseInsensitive:@"php"]);
            }
        }
        
        _flags._isWeb = (result) ? 1:0;
        _flags._isWeb_initialized = 1;
    }
    
    return (_flags._isWeb == 1);
}

- (BOOL)isPostscript;
{
    if (!_flags._isPostscript_initialized)
    {
        BOOL result = NO;

        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];

            result = ([ext isEqualToStringCaseInsensitive:@"eps"]);

            if (!result)
            {
                // check type
                int type = [_desc type];
                result = (type == 'EPS ');
            }
        }

        _flags._isPostscript = (result) ? 1:0;
        _flags._isPostscript_initialized = 1;
    }

    return (_flags._isPostscript == 1);
}

- (BOOL)isTIFF;
{
    if (!_flags._isTIFF_initialized)
    {
        BOOL result = NO;
		
		if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeTIFF);
		
        _flags._isTIFF = (result) ? 1:0;
        _flags._isTIFF_initialized = 1;
    }
	
    return (_flags._isTIFF == 1);
}

- (BOOL)isJPEG;
{
    if (!_flags._isJPEG_initialized)
    {
        BOOL result = NO;
		
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeJPEG);  // kUTTypeJPEG2000 ??
		
        _flags._isJPEG = (result) ? 1:0;
        _flags._isJPEG_initialized = 1;
    }
	
    return (_flags._isJPEG == 1);
}

- (BOOL)isPNG;
{
    if (!_flags._isPNG_initialized)
    {
        BOOL result = NO;
		
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypePNG);
		
        _flags._isPNG = (result) ? 1:0;
        _flags._isPNG_initialized = 1;
    }
	
    return (_flags._isPNG == 1);
}

- (BOOL)isHDR;
{
    if (!_flags._isHDR_initialized)
    {
        BOOL result = NO;
		
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
		{
			NSString* ext = [_desc extension];
			
            result = ([ext isEqualToStringCaseInsensitive:@"hdr"]);			
		}
		
        _flags._isHDR = (result) ? 1:0;
        _flags._isHDR_initialized = 1;
    }
	
    return (_flags._isHDR == 1);
}

- (BOOL)isPDF;
{
    if (!_flags._isPDF_initialized)
    {
		BOOL result = NO;

		if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypePDF);

        _flags._isPDF = (result) ? 1:0;
        _flags._isPDF_initialized = 1;
    }
	
    return (_flags._isPDF == 1);
}

- (BOOL)isEPS;
{
    if (!_flags._isEPS_initialized)
    {
        BOOL result = NO;
		
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];
			
            result = ([ext isEqualToStringCaseInsensitive:@"eps"]);
		}
		
        _flags._isEPS = (result) ? 1:0;
        _flags._isEPS_initialized = 1;
    }
	
    return (_flags._isEPS == 1);
}

- (BOOL)isIcon;
{
    if (!_flags._isIcon_initialized)
    {
        BOOL result = NO;

        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];

            result = ([ext isEqualToStringCaseInsensitive:@"icns"]);

            if (!result)
            {
                // check type
                int type = [_desc type];
                result = (type == 'icns');
            }
        }

        _flags._isIcon = (result) ? 1:0;
        _flags._isIcon_initialized = 1;
    }

    return (_flags._isIcon == 1);
}

- (BOOL)isDiskImage;
{
    if (!_flags._isDiskImage_initialized)
    {
        BOOL result = NO;

		if (_desc && ![_desc isDirectory] && ![_desc isAlias])
			result = UTTypeConformsTo ((CFStringRef) [_desc uniformTypeID], kUTTypeDiskImage);

        _flags._isDiskImage = (result) ? 1:0;
        _flags._isDiskImage_initialized = 1;
    }

    return (_flags._isDiskImage == 1);
}

- (BOOL)isRTFReadMeApplication;
{
    if (!_flags._isRTFReadMeApplication_initialized)
    {
        BOOL result = NO;
		
		if (_desc && [_desc isApplication] && [_desc isPackage])  // no classic apps
		{
			// bundle signature code must be "GRAr" or "????"
			if ([[_desc bundleSignature] isEqualToString:@"GRAr"] || [[_desc bundleSignature] isEqualToString:@"????"])
			{
				// extra sure, check for LSBackgroundOnly 
				NSBundle* bundle = [NSBundle bundleWithPath:[_desc path]];
				if (bundle) 
				{
					if ([[bundle infoDictionary] boolForKey:@"LSBackgroundOnly"])
					{
						// is there a single rtf file in the Resources folder?  what about rtfd? 
						NSArray* paths = [NSBundle pathsForResourcesOfType:@"rtf" inDirectory:[_desc path]];
						if ([paths count] == 1)
							result = YES;
					}
				}
			}
		}
		
        _flags._isRTFReadMeApplication = (result) ? 1:0;
        _flags._isRTFReadMeApplication_initialized = 1;
    }
	
    return (_flags._isRTFReadMeApplication == 1);
}

- (BOOL)isPDFReadMeApplication;
{
    if (!_flags._isPDFReadMeApplication_initialized)
    {
        BOOL result = NO;
		
		if (_desc && [_desc isApplication] && [_desc isPackage])  // no classic apps
		{
			// bundle signature code must be "GRAp" or "????"
			if ([[_desc bundleSignature] isEqualToString:@"GRAp"] || [[_desc bundleSignature] isEqualToString:@"????"])
			{
				NSBundle* bundle = [NSBundle bundleWithPath:[_desc path]];
				if (bundle) 
				{
					// extra sure, check for LSBackgroundOnly 
					if ([[bundle infoDictionary] boolForKey:@"LSBackgroundOnly"])
					{
						// is there a single rtf file in the Resources folder?  what about rtfd? 
						NSArray* paths = [NSBundle pathsForResourcesOfType:@"pdf" inDirectory:[_desc path]];
						if ([paths count] == 1)
							result = YES;
					}
				}
			}
		}
		
        _flags._isPDFReadMeApplication = (result) ? 1:0;
        _flags._isPDFReadMeApplication_initialized = 1;
    }
	
    return (_flags._isPDFReadMeApplication == 1);
}

- (BOOL)isHelpViewerPackage;
{
	// a localized bundle with localized html files
	if (!_flags._isHelpViewerPackage_initialized)
    {
        BOOL result = NO;
		
		if (_desc && [_desc isPackage])
		{
			// bundle signature code must be "BNDLhbwr", but I the extension should be enough
			if ([[_desc extension] isEqualToStringCaseInsensitive:@"help"])
			{
				// is there a single html file in the Resources folder?  
				NSArray* paths = [NSBundle pathsForResourcesOfType:@"html" inDirectory:[_desc path]];
				if ([paths count] == 1)
					result = YES;
				
				// not sure if needed, but being safe
				if (!result)
				{
					NSArray* paths = [NSBundle pathsForResourcesOfType:@"htm" inDirectory:[_desc path]];
					if ([paths count] == 1)
						result = YES;
				}
			}
		}
		
        _flags._isHelpViewerPackage = (result) ? 1:0;
        _flags._isHelpViewerPackage_initialized = 1;
    }
	
    return (_flags._isHelpViewerPackage == 1);	
}

- (BOOL)isTextClipping;
{
    if (!_flags._isTextClipping_initialized)
    {
        _flags._isTextClipping = [NTWeblocFile isTextWeblocFile:_desc];
        _flags._isTextClipping_initialized = 1;
    }

    return (_flags._isTextClipping == 1);
}

- (BOOL)isUnsanityAPEPackage;
{
    if (!_flags._isUnsanityAPEPackage_initialized)
    {
        BOOL result = NO;

        // must be a package
        if (_desc && [_desc isPackage] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];

            // has extension of .ape
            result = ([ext isEqualToStringCaseInsensitive:@"ape"]);
        }

        _flags._isUnsanityAPEPackage = (result) ? 1:0;
        _flags._isUnsanityAPEPackage_initialized = 1;
    }

    return (_flags._isUnsanityAPEPackage == 1);    
}

- (BOOL)isQuartzComposer;
{
	if (!_flags._isQuartzComposer_initialized)
    {
        BOOL result = NO;
		
        // must be a package
        if (_desc && [_desc isFile] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];
			
            // has extension of .ape
            result = ([ext isEqualToStringCaseInsensitive:@"qtz"]);
        }
		
        _flags._isQuartzComposer = (result) ? 1:0;
        _flags._isQuartzComposer_initialized = 1;
    }
	
    return (_flags._isQuartzComposer == 1);    	
}

- (BOOL)isAnimatedGif
{
    BOOL result = NO;
	
	// QTMovie not thread safe
	if (![NSThread inMainThread])
		return result;
	else
	{
		if ([self isImage])
		{
			int type = [_desc type];
			NSString* ext = [_desc extension];
			
			if ([ext isEqualToStringCaseInsensitive:@"gif"] || type == 'GIF ')
			{
				// open file with quicktime and see if there is more than one frame
				NSError* error=nil;
				QTMovie *movie = [QTMovie movieWithURL:[_desc URL] error:&error];
				Movie qtMovie = [movie quickTimeMovie];
				
				if (qtMovie)
				{
					int numSamples = GetMediaSampleCount(GetTrackMedia(GetMovieIndTrack(qtMovie, 1)));
					
					result = (numSamples > 1);
				}
			}
		}
	}
	
    return result;
}

- (BOOL)isFont;
{
    if (!_flags._isFont_initialized)
    {
        BOOL result = NO;
        
        if (_desc && ![_desc isDirectory] && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];
            
            result = ([ext isEqualToStringCaseInsensitive:@"dfont"] ||  // data fork true type font
                      [ext isEqualToStringCaseInsensitive:@"otf"] ||    // OpenType font
                      [ext isEqualToStringCaseInsensitive:@"bmap"] ||    // OS 9 font suitcase
                      [ext isEqualToStringCaseInsensitive:@"suit"] ||    // OS 9 font suitcase
                      [ext isEqualToStringCaseInsensitive:@"ttf"]);     // Window's true type font
            
            if (!result)
            {
                int type = [_desc type];
                int creator = [_desc creator];
                
                result = ((type == 'FFIL' && creator == 'DMOV') || // OS 9 font suitcase
                          (type == 'LWFN' && creator == 'ACp1'));  // PostScript Type 1 outline
            }
        }
        
        _flags._isFont = (result) ? 1:0;
        _flags._isFont_initialized = 1;
    }
    
    return (_flags._isFont == 1);
}

- (BOOL)isSavedSearch;
{
	if (!_flags._isSavedSearch_initialized)
    {
        BOOL result = NO;
        
        if (_desc && ![_desc isAlias])
        {
            NSString* ext = [_desc extension];
            
            result = ([ext isEqualToStringCaseInsensitive:@"savedSearch"] || [ext isEqualToStringCaseInsensitive:@"cannedSearch"]);
        }
        
        _flags._isSavedSearch = (result) ? 1:0;
        _flags._isSavedSearch_initialized = 1;
    }
    
    return (_flags._isSavedSearch == 1);	
}

// EPS is slow, PDF is handled by the PDFView, HDR is too slow
- (BOOL)isImageForPreview;
{
	BOOL result = NO;
	
	if ([self isImage] && ![self isPDF] && ![self isEPS] && ![self isHDR])
		result = YES;
	
	return result;
}

@end

// for extracting the content file from a package
@implementation NTFileTypeIdentifier (Content)

// only used if isRTFReadMeApplication returns YES
- (NTFileDesc*)rtfApplicationContent;
{
	// is there a single rtf file in the Resources folder?  what about rtfd? 
	NSArray* paths = [NSBundle pathsForResourcesOfType:@"rtf" inDirectory:[_desc path]];
	
	if ([paths count])
		return [NTFileDesc descResolve:[paths objectAtIndex:0]];
	
	return nil;	
}

// only used if isPDFReadMeApplication returns YES
- (NTFileDesc*)pdfApplicationContent;
{
	// is there a single rtf file in the Resources folder?  what about rtfd? 
	NSArray* paths = [NSBundle pathsForResourcesOfType:@"pdf" inDirectory:[_desc path]];
	
	if ([paths count])
		return [NTFileDesc descResolve:[paths objectAtIndex:0]];
	
	return nil;
}

- (NTFileDesc*)helpViewerPackageContent;
{
	// is there a single html file in the Resources folder?
	NSArray* paths = [NSBundle pathsForResourcesOfType:@"html" inDirectory:[_desc path]];
	
	if ([paths count])
		return [NTFileDesc descResolve:[paths objectAtIndex:0]];

	// also checking htm
	paths = [NSBundle pathsForResourcesOfType:@"htm" inDirectory:[_desc path]];
	
	if ([paths count])
		return [NTFileDesc descResolve:[paths objectAtIndex:0]];

	return nil;
}

@end
