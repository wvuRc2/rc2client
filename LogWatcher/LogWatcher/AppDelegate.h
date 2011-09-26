//
//  AppDelegate.h
//  LogWatcher
//
//  Created by Mark Lilback on 9/24/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) IBOutlet NSWindow *loginWindow;
@property (nonatomic, assign) NSInteger selectedServerIndex;

-(IBAction)doLogin:(id)sender;
@end
