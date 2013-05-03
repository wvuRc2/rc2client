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
	[savePanel beginWithCompletionHandler:^(NSInteger result) {
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
	NSNib *nib = [[NSNib alloc] initWithNibNamed:@"RCMPreviewImageView" bundle:nil];
	for (RCImage *img in availableImages) {
		NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:img.name action:@selector(selectImage:) keyEquivalent:@""];
		mi.representedObject = img;
		[mi setEnabled:YES];
		mi.target = self;
		mi.action = @selector(selectImage:);
		[nib instantiateNibWithOwner:mi topLevelObjects:nil];
		[menu addItem:mi];
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