//
//  ControlViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ControlViewController : UIViewController
@property (nonatomic, weak) IBOutlet UISegmentedControl *modeControl;

-(IBAction)changeMode:(id)sender;
@end
