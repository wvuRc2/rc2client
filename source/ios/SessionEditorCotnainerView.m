//
//  SessionEditorCotnainerView.m
//  Rc2Client
//
//  Created by Mark Lilback on 11/21/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "SessionEditorCotnainerView.h"
#import "SessionEditView.h"

@implementation SessionEditorCotnainerView

-(id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self.textView = [[SessionEditView alloc] initWithFrame:self.bounds];
		self.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.textView];
	}
	return self;
}

@end
