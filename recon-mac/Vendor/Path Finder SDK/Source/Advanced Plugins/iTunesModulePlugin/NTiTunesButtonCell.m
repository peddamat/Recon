#import "NTiTunesButtonCell.h"

@interface NTiTunesAttachmentCell : NSTextAttachmentCell
{
}

@end

@interface NTiTunesTextFieldCell (Private)
- (NSMutableParagraphStyle*)paragraphStyle:(NSTextAlignment)align;
- (NSDictionary*)sharedAttributes;
@end

@implementation NTiTunesTextFieldCell

- (id)initWithCoder:(NSCoder *)aDecoder;
{
	self = [super initWithCoder:aDecoder];
		
	return self;
}

- (void)appendImage:(NSImage*)image toString:(NSMutableAttributedString*)toString;
{
    static unsigned unique = 0;  // Cocoa can work correctly if the the name is the same, but this may make it faster
    NSFileWrapper* fileWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]] autorelease];
    [fileWrapper setPreferredFilename:[NSString stringWithFormat:@"icon%u.tiff", unique++]];
	
    NSTextAttachment *attachment = [[[NSTextAttachment alloc] initWithFileWrapper:fileWrapper] autorelease]; 
	
	[attachment setAttachmentCell:[[[NTiTunesAttachmentCell alloc] init] autorelease]];
	
    [(NSTextAttachmentCell*) [attachment attachmentCell] setImage:image];
    
    [toString insertAttributedString:[[[NSAttributedString alloc] initWithString:@" " attributes:[self sharedAttributes]] autorelease] atIndex:0];
    [toString insertAttributedString:[NSAttributedString attributedStringWithAttachment:attachment] atIndex:0];
}

- (NSImage*)songFileIcon;
{
	static NSImage* songFileIcon=nil;
	
	if (!songFileIcon)
	{
		NSImage* srcImage = [[[NSWorkspace sharedWorkspace] iconForFileType:@"aiff"] retain];
		[srcImage setSize:NSMakeSize(16,16)];
		
		static int kImageSize = 12;
		
		NTImageMaker* imageMaker = [NTImageMaker maker:NSMakeSize(kImageSize,kImageSize)];
		
		// resize with high quality
		[imageMaker lockFocus];
		{
			NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
			NSImageInterpolation imageInterpolation;
			
			// draw images at highest possible quality
			imageInterpolation = [currentContext imageInterpolation];
			[currentContext setImageInterpolation:NSImageInterpolationHigh];
			
			[srcImage drawInRect:NSMakeRect(0,0,kImageSize,kImageSize) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
			
			[currentContext setImageInterpolation:imageInterpolation];
		}
		songFileIcon = [[imageMaker unlockFocus] retain];
	}
	
	return songFileIcon;
}

- (void)setObjectValue:(id)obj;
{
	if (obj)
	{
		// convert to an attributed string with an icon
		NSMutableAttributedString* attrStr = [[[NSMutableAttributedString alloc] initWithString:obj attributes:[self sharedAttributes]] autorelease];
				
		[self appendImage:[self songFileIcon] toString:attrStr];
			
		[super setObjectValue:attrStr];
	}
	else
		[super setObjectValue:nil];
}

@end

@implementation NTiTunesTextFieldCell (Private)

- (NSMutableParagraphStyle*)paragraphStyle:(NSTextAlignment)align;
{
	NSMutableParagraphStyle* paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];	
	// [paragraphStyle setTighteningFactorForTruncation:-1]; // disable it
	[paragraphStyle setAlignment:align];
	
	return paragraphStyle;
}

- (NSDictionary*)sharedAttributes;
{
	static NSDictionary* shared = nil;
	if (!shared)
	{		
		// build dictionary
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		
		// [dict setObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName];
		[dict setObject:[self paragraphStyle:NSLeftTextAlignment] forKey:NSParagraphStyleAttributeName];
		
		shared = [[NSDictionary alloc] initWithDictionary:dict];
	}
	
	return shared;
}	

@end

@implementation NTiTunesAttachmentCell

- (NSPoint)cellBaselineOffset;
{
	NSPoint result = [super cellBaselineOffset];
	
	result.y -= 2;
	
	return result;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{	
	[super drawWithFrame:cellFrame inView:controlView];
}

@end

