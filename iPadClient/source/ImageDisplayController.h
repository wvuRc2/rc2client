//
//  ImageDisplayController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageHolderView;
@class RCImage;

@interface ImageDisplayController : UIViewController<MFMailComposeViewControllerDelegate>
@property (nonatomic, assign) IBOutlet UISegmentedControl *whatUp;
@property (nonatomic, retain) IBOutlet ImageHolderView *holder1;
@property (nonatomic, retain) IBOutlet ImageHolderView *holder2;
@property (nonatomic, retain) IBOutlet ImageHolderView *holder3;
@property (nonatomic, retain) IBOutlet ImageHolderView *holder4;
@property (nonatomic, copy) NSArray *allImages;
@property (nonatomic, copy) BasicBlock closeHandler;

-(IBAction)whatUpDawg:(id)sender;
-(IBAction)close:(id)sender;

-(void)loadImage:(RCImage*)img;
-(void)loadImages;
-(void)loadImage1:(RCImage*)img;
@end
