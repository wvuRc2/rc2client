//
//  SettingsController.h
//  iPadClient
//
//  Created by Mark Lilback on 9/2/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsController : UIViewController<UITextFieldDelegate,UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *settingsTable;
@property (nonatomic, strong) IBOutlet UITableViewCell *leftyCell;
@property (nonatomic, strong) IBOutlet UISwitch *leftySwitch;
@property (nonatomic, strong) IBOutlet UISwitch *dynKeyboardSwitch;
@property (strong, nonatomic) IBOutlet UIPickerView *keyboardPicker;
@property (strong, nonatomic) IBOutlet UITableViewCell *dynKeyCell;
@property (strong, nonatomic) IBOutlet UITextField *keyUrl1Field;
@property (strong, nonatomic) IBOutlet UITextField *keyUrl2Field;

-(IBAction)valueChanged:(id)sender;
-(IBAction)doClose:(id)sender;
@end
