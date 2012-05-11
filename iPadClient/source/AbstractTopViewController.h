//
//  AbstractTopViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Theme;

@interface AbstractTopViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIBarButtonItem *messagesButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *homeButton;
@property (nonatomic, strong) NSMutableArray *kvoTokens;

-(IBAction)doActionMenu:(id)sender;

//registered so subclasses can respond to theme changes. also called from viewDidLoad so intiial values can be set
-(void)updateForNewTheme:(Theme*)theme;

//this is called in dealloc, also should be called in viewDidUnload
-(void)freeUpMemory;

@end
