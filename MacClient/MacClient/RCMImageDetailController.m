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

-(void)awakeFromNib
{
	NSLog(@"awake");
}

@synthesize imageView;
@synthesize filePopUp;
@synthesize availableImages;
@synthesize arrayController;
@synthesize selectedImage;
@end
