//
//  SettingsController.h
//  iPadClient
//
//  Created by Mark Lilback on 9/2/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsController : UIViewController
@property (nonatomic, retain) IBOutlet UITableView *settingsTable;
@property (nonatomic, retain) IBOutlet UITableViewCell *leftyCell;
@property (nonatomic, retain) IBOutlet UISwitch *leftySwitch;

-(IBAction)valueChanged:(id)sender;
-(IBAction)doClose:(id)sender;
@end
