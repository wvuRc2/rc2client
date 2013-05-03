//
//  RCMImageDetailController.h
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RCMMultiUpView.h"

@class RCImage;

@interface RCMImageDetailController : AMViewController
@property (nonatomic, copy) NSArray *availableImages;
@property (nonatomic, strong) RCImage *selectedImage;

-(IBAction)saveImageAs:(id)sender;
@end

@interface RCMImageDetailView : AMControlledView <RCMMultiUpChildView>

@end