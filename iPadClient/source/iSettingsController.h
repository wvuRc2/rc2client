//
//  iSettingsController.h
//  iPadClient
//
//  Created by Mark Lilback on 2/8/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iSettingsController : UIViewController<UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITableView *settingsTable;
@property (nonatomic, strong) IBOutlet UITableViewCell *keyboardCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *themeCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *emailCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *twitterCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *smsCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *emailNoteCell;
@property (nonatomic, strong) IBOutlet UISwitch *emailNoteSwitch;
@property (nonatomic, strong) IBOutlet UILabel *keyboardLabel;
@property (nonatomic, strong) IBOutlet UILabel *themeLabel;
@property (nonatomic, strong) IBOutlet UITextField *emailField;
@property (nonatomic, strong) IBOutlet UITextField *twitterField;
@property (nonatomic, strong) IBOutlet UITextField *smsField;
@property (nonatomic, weak) UIPopoverController *containingPopover;
@end
