//
//  RCMImagePrintView.h
//  MacClient
//
//  Created by Mark Lilback on 10/18/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCMImagePrintView : NSView
-(id)initWithImages:(NSArray*)images;
//an array of RCImage objects
@property (nonatomic, copy) NSArray *images;
@end
