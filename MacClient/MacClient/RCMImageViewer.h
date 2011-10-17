//
//  RCMImageViewer.h
//  MacClient
//
//  Created by Mark Lilback on 10/17/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCMImageViewer : NSViewController
@property (nonatomic, strong) IBOutlet NSImageView *imageView;
@property (nonatomic, strong) NSArray *imageArray;
@property (nonatomic, strong) IBOutlet NSArrayController *imageArrayController;
@property (nonatomic, copy) NSString *displayedImageName;
-(void)displayImage:(NSString*)path;

-(IBAction)saveImageAs:(id)sender;
@end
