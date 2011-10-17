//
//  MCWebOutputController.h
//  MacClient
//
//  Created by Mark Lilback on 10/10/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MCWebOutputDelegate <NSObject>
-(void)handleImageRequest:(NSURL*)url;
-(void)previewImages:(NSArray*)imageUrls atPoint:(NSPoint)pt;
@end

@interface MCWebOutputController : AMViewController
@property (nonatomic, strong) IBOutlet WebView *webView;
@property (nonatomic, unsafe_unretained) IBOutlet id<MCWebOutputDelegate> delegate;
@end
