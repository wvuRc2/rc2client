//
//  iSettingsController.h
//  Rc2
//
//  Created by Mark Lilback on 2/8/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GradientButton;

@interface iSettingsController : UIViewController<UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITableView *settingsTable;
@property (nonatomic, weak) IBOutlet UITableViewCell *keyboardCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *themeCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *emailCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *twitterCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *smsCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *emailNoteCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *logoutCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *editThemeCell;
@property (nonatomic, weak) IBOutlet UISwitch *emailNoteSwitch;
@property (nonatomic, weak) IBOutlet GradientButton *logoutButton;
@property (nonatomic, weak) IBOutlet GradientButton *editThemeButton;
@property (nonatomic, weak) IBOutlet UILabel *keyboardLabel;
@property (nonatomic, weak) IBOutlet UILabel *themeLabel;
@property (nonatomic, weak) IBOutlet UITextField *emailField;
@property (nonatomic, weak) IBOutlet UITextField *twitterField;
@property (nonatomic, weak) IBOutlet UITextField *smsField;
@property (nonatomic, strong) UIPopoverController *containingPopover;
@end
