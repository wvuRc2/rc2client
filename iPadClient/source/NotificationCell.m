//
//  NotificationCell.m
//  iPadClient
//
//  Created by Mark Lilback on 5/18/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "NotificationCell.h"

@interface NotificationCell()
@property (nonatomic, strong) IBOutlet UILabel *typeLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@end

@implementation NotificationCell

-(NSString*)stringForType:(NSInteger)noteType
{
	switch (noteType) {
		case 0:
		default:
			return @"New Message";
		case 1:
			return @"Assignment Graded";
	}
}

-(void)setNote:(NSDictionary *)note
{
	_note = note;
	self.typeLabel.text = [self stringForType:[[note objectForKey:@"notetype"] intValue]];
	self.messageLabel.text = [note objectForKey:@"details"];
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[note objectForKey:@"datecreated"] doubleValue] / 1000];
	self.dateLabel.text = [self.dateFormatter stringFromDate:date];
}

@synthesize note=_note;
@synthesize typeLabel=_typeLabel;
@synthesize dateLabel=_dateLabel;
@synthesize messageLabel=_messageLabel;
@synthesize dateFormatter=_dateFormatter;
@end
