//
//  ImageDisplayController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AbstractTopViewController.h"

@class ImageHolderView;
@class RCImage;

@interface ImageDisplayController : AbstractTopViewController<MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) IBOutlet UISegmentedControl *whatUp;
@property (nonatomic, strong) IBOutlet ImageHolderView *holder1;
@property (nonatomic, strong) IBOutlet ImageHolderView *holder2;
@property (nonatomic, strong) IBOutlet ImageHolderView *holder3;
@property (nonatomic, strong) IBOutlet ImageHolderView *holder4;
@property (nonatomic, copy) NSArray *allImages;
@property (nonatomic, copy) BasicBlock closeHandler;

-(IBAction)whatUpDawg:(id)sender;
-(IBAction)close:(id)sender;

-(void)loadImages;
-(void)setImageDisplayCount:(NSInteger)imgCount; //1, 2, or 4
@end
