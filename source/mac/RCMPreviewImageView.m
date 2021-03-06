//
//  RCMPreviewImageView.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/3/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCMPreviewImageView.h"
#import "RCImage.h"
#import <CoreImage/CoreImage.h>

@interface RCMPreviewImageView()
@property (atomic) BOOL generatingRawImage;
@end

@implementation RCMPreviewImageView

+(NSSet*)keyPathsForValuesAffectingRawImage
{
	return [NSSet setWithObject:@"image"];
}

- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

-(void)mouseUp:(NSEvent *)theEvent
{
	NSMenuItem *mi = [self enclosingMenuItem];
	NSMenu *menu = [mi menu];
	[menu cancelTracking];
	[menu performActionForItemAtIndex:[menu indexOfItem:mi]];
}

-(void)setHighlighted:(BOOL)highlighted
{
	if (_highlighted == highlighted)
		return;
	_highlighted = highlighted;
	[self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)dirtyRect
{
	if (_highlighted) {
		[[NSColor selectedMenuItemColor] set];
	} else {
		[[NSColor whiteColor] set];
	}
	NSRectFill(dirtyRect);
}

-(void)setImage:(RCImage *)image
{
	_image = image;
	self.imageView.image = self.rawImage;
}

-(void)setSharpen:(BOOL)sharpen
{
	_sharpen = sharpen;
	_rawImage = nil;
	self.imageView.image = self.rawImage;
}

-(NSImage*)rawImage
{
	if (self.generatingRawImage)
		return _image.image;
	if (nil == _rawImage && _image) {
		if (_sharpen) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
				CIFilter *filter = [CIFilter filterWithName:@"CISharpenLuminance"];
				[filter setValue:[CIImage imageWithContentsOfURL:self.image.fileUrl] forKey:@"inputImage"];
				[filter setValue:@0.7 forKey:@"inputSharpness"];
				CIImage *cimg = [filter valueForKey:@"outputImage"];

				NSImage *nimg = [[NSImage alloc] initWithSize:NSMakeSize([cimg extent].size.width, [cimg extent].size.height)];
				[nimg addRepresentation:[NSCIImageRep imageRepWithCIImage:cimg]];
				_rawImage = [NSImage imageWithData:[nimg pngData]];
				dispatch_async(dispatch_get_main_queue(), ^{
					self.imageView.image = _rawImage;
				});
			});
		} else {
			_rawImage = _image.image;
		}
	}
	return _rawImage;
}

@end
