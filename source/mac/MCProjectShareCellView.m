//
//  MCProjectShareCellView.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/22/14.
//  Copyright 2014 West Virginia University. All rights reserved.
//

#import "MCProjectShareCellView.h"

@interface MCProjectShareCellView ()
@property (nonatomic, weak) IBOutlet NSTextField *firstField;
@property (nonatomic, weak) IBOutlet NSTextField *secondField;
@end

@implementation MCProjectShareCellView

-(void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];
	if (nil == objectValue)
		return;
	NSString *fname = [objectValue valueForKey:@"firstname"];
	NSString *lname = [objectValue valueForKey:@"lastname"];
	if (lname == nil)
		lname = @"";
	if (fname.length > 0)
		self.firstField.stringValue = [NSString stringWithFormat:@"%@ %@", fname, lname];
	else
		self.firstField.stringValue = lname;
	self.secondField.stringValue = [objectValue valueForKey:@"email"];
}
@end
