//
//  MacMainWindowController.h
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MacClientAbstractViewController;
@class RCWorkspace;

@interface MacMainWindowController : NSWindowController<NSWindowDelegate>
@property (strong, nonatomic) AMMacNavController *navController;
@property (strong, nonatomic) MacClientAbstractViewController *detailController;
@property (strong) IBOutlet AMControlledView *detailContainer;
@property (strong) IBOutlet NSMenu *addToolbarMenu;
-(void)openSession:(RCWorkspace*)wspace inNewWindow:(BOOL)inNewWindow;

-(IBAction)doBackToMainView:(id)sender;
@end
