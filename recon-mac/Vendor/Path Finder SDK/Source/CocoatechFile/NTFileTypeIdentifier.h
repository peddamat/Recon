//
//  NTFileTypeIdentifier.h
//  CocoatechFile
//
//  Created by sgehrman on Sun Sep 23 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFileDesc;

@interface NTFileTypeIdentifier : NSObject
{
    NTFileDesc* _desc;

    // bools with a flag, uses less ram than an int
    struct __tflags
    {
        // an animated gif can be both image and movie
        unsigned int        _isImage:1;
        unsigned int        _isImage_initialized:1;

        unsigned int        _isMovie:1;
        unsigned int        _isMovie_initialized:1;

        unsigned int        _isMP3:1;
        unsigned int        _isMP3_initialized:1;

        unsigned int        _isAudio:1;
        unsigned int        _isAudio_initialized:1;

        unsigned int        _isText:1;
        unsigned int        _isText_initialized:1;

        unsigned int        _isTextClipping:1;
        unsigned int        _isTextClipping_initialized:1;

        unsigned int        _isURLClipping:1;
        unsigned int        _isURLClipping_initialized:1;

		unsigned int        _isSavedSearch:1;
        unsigned int        _isSavedSearch_initialized:1;
		
        unsigned int        _isRTF:1;
        unsigned int        _isRTF_initialized:1;

        unsigned int        _isRTFD:1;
        unsigned int        _isRTFD_initialized:1;

        unsigned int        _isHTML:1;
        unsigned int        _isHTML_initialized:1;

        unsigned int        _isWeb:1;
        unsigned int        _isWeb_initialized:1;

		unsigned int        _isFlashVideo:1;
        unsigned int        _isFlashVideo_initialized:1;

		unsigned int        _isFlash:1;
        unsigned int        _isFlash_initialized:1;
		
		unsigned int        _isWebArchive:1;
		unsigned int        _isWebArchive_initialized:1;

        unsigned int        _isPostscript:1;
        unsigned int        _isPostscript_initialized:1;

		unsigned int        _isZip:1;
        unsigned int        _isZip_initialized:1;

        unsigned int        _isTIFF:1;
        unsigned int        _isTIFF_initialized:1;

		unsigned int        _isJPEG:1;
        unsigned int        _isJPEG_initialized:1;

		unsigned int        _isPNG:1;
        unsigned int        _isPNG_initialized:1;

		unsigned int        _isHDR:1;
        unsigned int        _isHDR_initialized:1;

        unsigned int        _isPDF:1;
        unsigned int        _isPDF_initialized:1;

		unsigned int        _isEPS:1;
        unsigned int        _isEPS_initialized:1;

        unsigned int        _isMSWord:1;
        unsigned int        _isMSWord_initialized:1;

		unsigned int        _isChat:1;
        unsigned int        _isChat_initialized:1;

        unsigned int        _isDiskImage:1;
        unsigned int        _isDiskImage_initialized:1;

        unsigned int        _isIcon:1;
        unsigned int        _isIcon_initialized:1;

		unsigned int        _isBinaryPList:1;
        unsigned int        _isBinaryPList_initialized:1;

        unsigned int        _isClassicSound:1;
        unsigned int        _isClassicSound_initialized:1;

        unsigned int        _isUnsanityAPEPackage:1;
        unsigned int        _isUnsanityAPEPackage_initialized:1;

        unsigned int        _isFont:1;
        unsigned int        _isFont_initialized:1;

		unsigned int        _isQuartzComposer:1;
        unsigned int        _isQuartzComposer_initialized:1;

		unsigned int        _isRTFReadMeApplication:1;
        unsigned int        _isRTFReadMeApplication_initialized:1;

		unsigned int        _isPDFReadMeApplication:1;
        unsigned int        _isPDFReadMeApplication_initialized:1;

		unsigned int        _isHelpViewerPackage:1;
        unsigned int        _isHelpViewerPackage_initialized:1;

    } _flags;
}

+ (id)typeIdentifier:(NTFileDesc*)descEntry;

- (BOOL)isImage;
- (BOOL)isText;
- (BOOL)isRTF;
- (BOOL)isRTFD;
- (BOOL)isMSWord;
- (BOOL)isHTML;
- (BOOL)isZip;

- (BOOL)isWeb; // html, swf, flv, asp, php etc
- (BOOL)isFlashVideo; // flv
- (BOOL)isFlash;  // swf
- (BOOL)isWebArchive; // .webarchive created by Safari

- (BOOL)isMovie;
- (BOOL)isFont;
- (BOOL)isMP3;
- (BOOL)isAudio;
- (BOOL)isClassicSound;  // classic sound resource
- (BOOL)isPostscript;
- (BOOL)isTIFF;
- (BOOL)isChat;
- (BOOL)isJPEG;
- (BOOL)isPNG;
- (BOOL)isHDR;
- (BOOL)isPDF;
- (BOOL)isEPS;
- (BOOL)isIcon;
- (BOOL)isDiskImage;
- (BOOL)isTextClipping;
- (BOOL)isUnsanityAPEPackage;
- (BOOL)isQuartzComposer;
- (BOOL)isSavedSearch;
- (BOOL)isBinaryPList;  // .plist or .strings (iphone)

- (BOOL)isRTFReadMeApplication;
- (BOOL)isPDFReadMeApplication;

- (BOOL)isHelpViewerPackage;

- (BOOL)isAnimatedGif;

	// EPS is slow, PDF is handled by the PDFView
- (BOOL)isImageForPreview;

@end

// for extracting the content file from a package
@interface NTFileTypeIdentifier (Content)

- (NTFileDesc*)rtfApplicationContent;
- (NTFileDesc*)pdfApplicationContent;

- (NTFileDesc*)helpViewerPackageContent;

@end

