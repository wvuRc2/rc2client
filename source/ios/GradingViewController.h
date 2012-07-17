//
//  GradingViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "AbstractTopViewController.h"

@interface GradingViewController : AbstractTopViewController<UITableViewDataSource,UITableViewDelegate>

-(IBAction)editPdf:(id)sender;
-(void)handleUrl:(NSURL*)url;
@end
