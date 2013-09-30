//
//  KTPanel.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/30/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class kTController;

@interface KTPanel : NSObject
@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, weak) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UIView *view;

-(id)initWithNibName:(NSString*)nibName controller:(kTController*)controller;
@end
