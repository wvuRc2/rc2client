//
//  MacSessionView.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/3/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "MacSessionView.h"

@interface MacSessionView()
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leftXConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *editorWidthConstraint;
@property (nonatomic, weak) IBOutlet NSView *splitterView;
@end

@implementation MacSessionView

- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	self.splitterView.wantsLayer = YES;
	self.splitterView.layer.backgroundColor = [NSColor blackColor].CGColor;
	self.editorWidthConstraint.constant = 300;
}

-(void)embedOutputView:(NSView *)newView
{
	newView.frame = self.outputView.bounds;
	[self.outputView addSubview:newView];
	NSDictionary *dict = NSDictionaryOfVariableBindings(newView);
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[newView]-|" options:0 metrics:nil views:dict]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[newView]-|" options:0 metrics:nil views:dict]];
}

-(IBAction)toggleLeftView:(id)sender
{
	CGFloat newX = NSMinX(self.leftView.frame) >= 0 ? -171 : 0;
	[[self.leftXConstraint animator] setConstant:newX];
}

@end
