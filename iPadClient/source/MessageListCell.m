//
//  MessageListCell.m
//  iPadClient
//
//  Created by Mark Lilback on 9/4/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MessageListCell.h"
#import "RCMessage.h"

@interface MessageListCell() {
	CGSize _origSize;
}
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) RCMessage *theMessage;
@end

@implementation MessageListCell

-(void)dealloc
{
	self.theMessage=nil;
	self.dateFormatter=nil;
	self.priorityImages=nil;
	[super dealloc];
}

-(void)awakeFromNib
{
	self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
	self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
	_origSize = self.frame.size;
}

- (void)didMoveToSuperview
{
	CGRect r = CGRectInset([self frame], -4, -4);
	self.frame = r;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(CGFloat)setMessage:(RCMessage *)message selected:(BOOL)selected
{
	self.theMessage = message;
	self.subjectLabel.text = message.subject;
	if (nil == message.sender)
		self.fromLabel.text = @"Rc² System";
	else
		self.fromLabel.text = message.sender;
	self.dateLabel.text = [self.dateFormatter stringFromDate:message.dateSent];
	self.priorityFlag.image = [self.priorityImages objectAtIndex:[message.priority intValue]];
	self.bodyView.bodyText=nil;
	if (selected) {
		self.bodyView.bodyText = message.body;
		[self.bodyView setNeedsDisplay];
		return [self calculateHeightWithBody:message.body];
	}
	return 0;
}

-(CGFloat)defaultCellHeight
{
	return self.bodyView.frame.origin.y;
}

-(CGFloat)calculateHeightWithBody:(NSString*)body
{
	UIFont *theFont = [UIFont systemFontOfSize:14];
	CGRect textRect = self.bodyView.frame;
	textRect.size.height = 100;
	CGSize sz = [body sizeWithFont:theFont constrainedToSize:textRect.size lineBreakMode:UILineBreakModeWordWrap];
	textRect.size.height = sz.height;
	self.bodyView.frame = textRect;
	self.bodyView.bodyText = self.theMessage.body;
	[self.bodyView setNeedsDisplay];
	return self.defaultCellHeight + sz.height + 20; //some margin
}

@synthesize subjectLabel;
@synthesize fromLabel;
@synthesize dateLabel;
@synthesize priorityFlag;
@synthesize bodyView;
@synthesize dateFormatter;
@synthesize priorityImages;
@synthesize view;
@synthesize theMessage;
@synthesize deleteButton;
@end


@implementation BodyDrawingView

-(void)drawRect:(CGRect)rect
{
	UIFont *theFont = [UIFont systemFontOfSize:14];
	[self.bodyText drawInRect:rect withFont:theFont lineBreakMode:UILineBreakModeWordWrap];
}

@synthesize bodyText;
@end