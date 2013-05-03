//
//  RCMPreviewImageView.h
//  Rc2Client
//
//  Created by Mark Lilback on 5/3/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCImage;

@interface RCMPreviewImageView : NSView
@property (nonatomic, strong) RCImage *image;
@property (nonatomic, strong) NSImage *rawImage;
@property (nonatomic, weak) IBOutlet NSImageView *imageView;
@property (nonatomic) BOOL highlighted;
@property (nonatomic) BOOL sharpen;
@end
