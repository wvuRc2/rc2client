//
//  AddFullConstraintsView.m
//  Rc2Client
//
//  Created by Mark Lilback on 8/21/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "AddFullConstraintsView.h"

@implementation AddFullConstraintsView

-(void)didMoveToSuperview
{
	if (self.superview) {
		NSDictionary *views = NSDictionaryOfVariableBindings(self);
		[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[self]|" options:0 metrics:nil views:views]];
		[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[self]|" options:0 metrics:nil views:views]];
	}
}

@end
