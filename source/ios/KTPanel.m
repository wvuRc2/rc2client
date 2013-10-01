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

-(IBAction)insertString:(id)sender
{
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