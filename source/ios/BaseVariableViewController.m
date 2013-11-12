//
//  BaseVariableViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 11/11/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "BaseVariableViewController.h"
#import "VariableSpreadsheetController.h"
#import "VariableListController.h"
#import "VariableDetailViewController.h"
#import "RCSession.h"
#import "RCList.h"

@interface BaseVariableViewController ()

@end

@implementation BaseVariableViewController

-(void)showVariableDetails:(RCVariable*)var
{
	if (var.type == eVarType_Matrix || var.type == eVarType_DataFrame) {
		VariableSpreadsheetController *ssheet = [[VariableSpreadsheetController alloc] init];
		ssheet.variable = (id)var;
		[self.navigationController pushViewController:ssheet animated:YES];
	} else if (var.type == eVarType_List) {
		RCList *list = (RCList*)var;
		VariableListController *vlc = [[VariableListController alloc] init];
		vlc.listVariable = list;
		vlc.session = self.session;
		[self.navigationController pushViewController:vlc animated:YES];
		if (!list.hasValues) {
			[self.session requestListVariableData:list block:^(RCList *aList) {
				vlc.listVariable = aList;
			}];
		}
	} else {
		VariableDetailViewController *detail = [[VariableDetailViewController alloc] init];
		detail.variable = var;
		[self.navigationController pushViewController:detail animated:YES];
	}
}
@end
