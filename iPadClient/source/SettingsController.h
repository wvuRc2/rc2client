//
//  SettingsController.h
//  iPadClient
//
//  Created by Mark Lilback on 9/2/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsController : UIViewController<UITextFieldDelegate,UITableViewDelegate>
@property (nonatomic, retain) IBOutlet UITableView *settingsTable;
@property (nonatomic, retain) IBOutlet UITableViewCell *leftyCell;
@property (nonatomic, retain) IBOutlet UISwitch *leftySwitch;
@property (nonatomic, retain) IBOutlet UISwitch *dynKeyboardSwitch;
@property (retain, nonatomic) IBOutlet UIPickerView *keyboardPicker;
@property (retain, nonatomic) IBOutlet UITableViewCell *dynKeyCell;
@property (retain, nonatomic) IBOutlet UITextField *keyUrl1Field;
@property (retain, nonatomic) IBOutlet UITextField *keyUrl2Field;

-(IBAction)valueChanged:(id)sender;
-(IBAction)doClose:(id)sender;
@end
