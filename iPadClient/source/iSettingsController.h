//
//  iSettingsController.h
//  iPadClient
//
//  Created by Mark Lilback on 2/8/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iSettingsController : UIViewController
@property (nonatomic, strong) IBOutlet UITableView *settingsTable;
@property (nonatomic, strong) IBOutlet UITableViewCell *passwordCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *keyboardCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *themeCell;
@property (nonatomic, strong) IBOutlet UILabel *keyboardLabel;
@property (nonatomic, strong) IBOutlet UILabel *themeLabel;
@property (nonatomic, weak) UIPopoverController *containingPopover;
@end
