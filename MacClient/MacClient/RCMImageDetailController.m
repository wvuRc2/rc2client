//
//  RCMImageDetailController.m
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMImageDetailController.h"
#import "RCImage.h"

@implementation RCMImageDetailController

- (id)init
{
	if ((self = [super initWithNibName:@"RCMImageDetailController" bundle:nil])) {
	}
	return self;
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

@synthesize imageView;
@synthesize filePopUp;
@synthesize availableImages;
@synthesize arrayController;
@synthesize selectedImage;
@end
