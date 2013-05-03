//
//  RCMImageDetailController.m
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMImageDetailController.h"
#import "RCImage.h"
#import "RCMPreviewImageView.h"

@interface RCMImageDetailController () <NSMenuDelegate>

@end

//fix crash on back for this class
@implementation RCMImageDetailController

- (id)init
{
	if ((self = [super initWithNibName:@"RCMImageDetailController" bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	self.imageView.imageFrameStyle = NSImageFramePhoto;
/*	NSView *blockView = [[NSView alloc] init];
	[self.view addSubview:blockView];
	[blockView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[blockView setWantsLayer:YES];
	blockView.layer.backgroundColor = [NSColor cgBlackColor];
	NSDictionary *viewd = @{@"block":blockView, @"imgv":self.imageView};
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[block]-0-|" options:0 metrics:nil views:viewd]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[block]-0-[imgv]" options:0 metrics:nil views:viewd]];
*/
	self.view.wantsLayer = YES;
	self.view.layer.backgroundColor = [NSColor cgBlackColor];
}

-(IBAction)saveImageAs:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"png"]];
	[savePanel setNameFieldStringValue:self.selectedImage.name];
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSData *data = [self.selectedImage.image pngData];
			[data writeToURL:[savePanel URL] atomically:YES];
		}
	}];
}

-(void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{
	for (NSMenuItem *mi in menu.itemArray)
		[(RCMPreviewImageView*)mi.view setHighlighted:NO];
	[(RCMPreviewImageView*)item.view setHighlighted:YES];
}

-(void)selectImage:(id)sender
{
	self.selectedImage = [sender representedObject];
}

-(void)setAvailableImages:(NSArray *)availableImages
{
	_availableImages = [availableImages copy];
	NSMenu *menu = self.filePopUp.menu;
	[menu removeAllItems];

	//we are going to use these filters so we can sharpen hard to distinguish images
	CIFilter *avgFilter = [CIFilter filterWithName:@"CIAreaAverage"];
	CIFilter *greyFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
	[avgFilter setDefaults];
	[greyFilter setDefaults];
	[greyFilter setValue:[CIColor colorWithCGColor:[NSColor cgBlackColor]] forKey:@"inputColor"];

	NSNib *nib = [[NSNib alloc] initWithNibNamed:@"RCMPreviewImageView" bundle:nil];
	for (RCImage *img in availableImages) {
		NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:img.name action:@selector(selectImage:) keyEquivalent:@""];
		mi.representedObject = img;
		[mi setEnabled:YES];
		mi.target = self;
		mi.action = @selector(selectImage:);
		[nib instantiateNibWithOwner:mi topLevelObjects:nil];
		[menu addItem:mi];
		[(RCMPreviewImageView*)mi.view setImage:img];
		//see if the image is is dark after switching to monotone and getting average color
		CIImage *cimg = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:img.path]];
		CGRect inputExtent = [cimg extent];
		CIVector *extent = [CIVector vectorWithX:inputExtent.origin.x
											   Y:inputExtent.origin.y
											   Z:inputExtent.size.width
											   W:inputExtent.size.height];
		[avgFilter setValue:extent forKey:@"inputExtent"];
		[avgFilter setValue:cimg forKey:@"inputImage"];
		CIImage *rimg = [avgFilter valueForKey:@"outputImage"];
		[greyFilter setValue:rimg forKey:@"inputImage"];
		rimg = [greyFilter valueForKey:@"outputImage"];
		NSBitmapImageRep *brep = [[NSBitmapImageRep alloc] initWithCIImage:rimg];
		NSColor *avgColor = [brep colorAtX:0 y:0];
		//all three components should be the same. 
		if ([avgColor redComponent] > 0.9)
			[(RCMPreviewImageView*)mi.view setSharpen:YES];
	}
}

@end

@implementation RCMImageDetailView

-(void)awakeFromNib
{
	self.translatesAutoresizingMaskIntoConstraints = NO;
}

@synthesize multiHConstraint, multiWConstraint, multiYConstraint, multiXConstraint;

@end