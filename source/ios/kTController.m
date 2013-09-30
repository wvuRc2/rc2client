//
//  kTController.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/30/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "kTController.h"
#import "KTPanel.h"

@interface kTController ()
@property (nonatomic, copy, readwrite) NSArray *panels;
@property (nonatomic, strong, readwrite) UIView *view;
@end

@implementation kTController

- (id)init
{
	if ((self = [super init])) {
		KTPanel *first = [[KTPanel alloc] initWithNibName:@"KTExecutePanel" controller:self];
		self.panels = @[first];
		self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 53)];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

		UIInputView *iview = [[UIInputView alloc] initWithFrame:self.view.frame inputViewStyle:UIInputViewStyleDefault];
		[iview addSubview:self.view];
		self.inputView = iview;

		[self.view addSubview:first.view];
		[self orientationDidChange:nil]; //force initial sizing
}
	return self;
}

-(void)nextPanel:(id)sender
{
	
}

-(void)previousPanel:(id)sender
{
	
}


-(void)orientationDidChange:(NSNotification*)note
{
	CGRect r = self.view.frame;
	BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	if (isLandscape) {
		r.size.width =1024;
	} else {
		r.size.width = 768;
	}
	self.view.frame = r;
	[self.view setNeedsUpdateConstraints];
	for (UIView *v in self.view.subviews)
		[v setNeedsUpdateConstraints];
}
@end
