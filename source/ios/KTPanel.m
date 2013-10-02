//
//  KTPanel.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/30/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "KTPanel.h"
#import "kTController.h"

@interface KTPanel ()
@property (nonatomic, weak) kTController *controller;
@property (nonatomic, copy) NSString *panelName;
@end

@interface KTPanelView : UIView
@property (nonatomic) BOOL installedConstraints;
@end

@implementation KTPanel

-(id)initWithNibName:(NSString*)nibName controller:(kTController*)controller
{
	if ((self = [super init])) {
		self.controller = controller;
		UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
		[nib instantiateWithOwner:self options:nil];
		self.panelName = nibName;
	}
	return self;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"%@ %@", super.description, self.panelName];
}

-(void)panelWillAppear
{
	//for each button, grab the touch up selector. if delegate responds to kt_selname then enable the button
	for (UIView *view in self.view.subviews) {
		if ([view isKindOfClass:[UIButton class]]) {
			UIButton *button = (UIButton*)view;
			NSString *selstr = [[button actionsForTarget:self forControlEvent:UIControlEventTouchUpInside] firstObject];
			button.enabled = NO;
			if (selstr) {
				NSString *delSel = [@"kt_" stringByAppendingString:selstr];
				SEL sel = NSSelectorFromString(delSel);
				button.enabled = sel != nil && [self.controller.delegate respondsToSelector:sel];
				if (button.enabled)
					button.enabled = [self.controller.delegate kt_enableButtonWithSelector:sel];
			}
		}
	}
}

-(IBAction)executeLine:(id)sender
{
	[self.controller.delegate kt_executeLine:sender];
}

-(IBAction)execute:(id)sender
{
	[self.controller.delegate kt_execute:sender];
}

-(IBAction)source:(id)sender
{
	[self.controller.delegate kt_source:sender];
}

-(IBAction)insertString:(id)sender
{
	[self.controller.delegate kt_insertString:[[sender titleLabel] text]];
}

-(IBAction)leftArrow:(id)sender
{
	[self.controller.delegate kt_leftArrow:sender];
}

-(IBAction)rightArrow:(id)sender
{
	[self.controller.delegate kt_rightArrow:sender];
}

-(IBAction)upArrow:(id)sender
{
	[self.controller.delegate kt_upArrow:sender];
}

-(IBAction)downArrow:(id)sender
{
	[self.controller.delegate kt_downArrow:sender];
}

@end

@implementation KTPanelView

-(void)awakeFromNib
{
	self.translatesAutoresizingMaskIntoConstraints = NO;
	for (id view in self.subviews) {
		if ([view isKindOfClass:[UIButton class]]) {
			UIButton *button = view;
			button.layer.masksToBounds = NO;
			button.layer.shadowColor = [UIColor blackColor].CGColor;
			button.layer.shadowOffset = CGSizeMake(0, 1);
			button.layer.shadowOpacity = 0.5;
			button.layer.shadowRadius = 1;
			button.layer.cornerRadius = 6;
			button.tintColor = [UIColor blackColor];
		}
	}
}

-(void)updateConstraints
{
	if (!self.installedConstraints) {
		[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[self]|" options:0 metrics:Nil views:NSDictionaryOfVariableBindings(self)]];
//		[self.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[self]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(self)]];
		self.installedConstraints = YES;
	}
	[super updateConstraints];
}

@end