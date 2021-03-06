//
//  AbstractTopViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Rc2NavBarChildProtocol.h"

@class Theme;
@class RCWorkspace;

@interface AbstractTopViewController : UIViewController<Rc2NavBarChildProtocol>

//from Rc2NavBarChildProtocol protocol
@property (nonatomic, copy, readonly) NSArray *standardLeftNavBarItems;
@property (nonatomic, copy, readonly) NSArray *standardRightNavBarItems;

@property (nonatomic, readonly) BOOL isSettingsPopoverVisible;

-(void)closeSettingsPopoverAnimated:(BOOL)animate;



@property (nonatomic, strong) IBOutlet UIBarButtonItem *messagesButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *homeButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *gradingButton;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;

//subclasses can implement this to adjust things on login/logout. must call super
-(void)adjustInterfaceBasedOnLogin;

//registered so subclasses can respond to theme changes. also called from viewDidLoad so intiial values can be set
-(void)updateForNewTheme:(Theme*)theme;

///called when settings are to be displayed to get workspace to show settings for. Defaults to nil.
-(RCWorkspace*)workspaceForSettings;
@end
