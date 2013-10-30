//
//  RCMImageViewer.h
//  MacClient
//
//  Created by Mark Lilback on 10/17/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCWorkspace;
@class RCImage;

@interface RCMImageViewer : AMViewController
@property (nonatomic, strong) IBOutlet NSImageView *imageView;
@property (nonatomic, strong) NSArray *imageArray;
@property (nonatomic, strong) RCWorkspace *workspace;
@property (nonatomic, strong) IBOutlet NSArrayController *imageArrayController;
@property (nonatomic, copy) NSString *displayedImageName;
@property (nonatomic, copy) BasicBlock detailsBlock;

-(void)displayImage:(RCImage*)image;

-(IBAction)saveImageAs:(id)sender;
-(IBAction)showImageDetails:(id)sender;
@end
