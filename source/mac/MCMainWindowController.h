//
//  MCMainWindowController.h
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MCAbstractViewController;
@class RCWorkspace;
@class RCFile;

@interface MCMainWindowController : NSWindowController<NSWindowDelegate>
@property (strong, nonatomic) AMMacNavController *navController;
@property (strong, nonatomic) MCAbstractViewController *detailController;
@property (strong) IBOutlet AMControlledView *detailContainer;
@property (strong) IBOutlet NSMenu *addToolbarMenu;
@property (strong) IBOutlet NSView *rightStatusView;

-(void)openSession:(RCWorkspace*)wspace file:(RCFile*)initialFile inNewWindow:(BOOL)inNewWindow;
-(void)openSession:(RCWorkspace*)wspace inNewWindow:(BOOL)inNewWindow;
-(IBAction)showAdminTools:(id)sender;

-(void)showViewController:(AMViewController*)controller;
-(void)displayPdfFile:(RCFile*)file;
-(void)popCurrentViewController;

-(IBAction)doBackToMainView:(id)sender;
@end
