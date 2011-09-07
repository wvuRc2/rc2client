//
//  ThemePicker.h
//  iPadClient
//
//  Created by Mark Lilback on 9/6/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThemePicker : UIViewController

@property (retain, nonatomic) IBOutlet UIPickerView *picker;
@property (retain, nonatomic) IBOutlet UITextField *customUrlField;
- (IBAction)doCancel:(id)sender;
- (IBAction)doDone:(id)sender;
@end
