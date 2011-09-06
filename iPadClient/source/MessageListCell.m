//
//  MessageListCell.m
//  iPadClient
//
//  Created by Mark Lilback on 9/4/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MessageListCell.h"
#import "RCMessage.h"
#import "ThemeEngine.h"

@interface MessageListCell() {
	CGSize _origSize;
}
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) RCMessage *theMessage;
@property (nonatomic, retain) CAGradientLayer *gl;
@property (nonatomic, retain) NSArray *normalColors;
@property (nonatomic, retain) NSArray *selectedColors;
@end

@implementation MessageListCell

@synthesize gl;
@synthesize normalColors;
@synthesize selectedColors;

-(void)dealloc
{
	self.gl=nil;
	self.selectedColors=nil;
	self.normalColors=nil;
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

	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	self.normalColors = [NSArray arrayWithObjects:
				   (id)[theme colorForKey:@"MessageCellStart"].CGColor,
				   (id)[theme colorForKey:@"MessageCellEnd"].CGColor, nil];
	self.selectedColors = [NSArray arrayWithObjects:
						 (id)[theme colorForKey:@"MessageSelectedStart"].CGColor,
						 (id)[theme colorForKey:@"MessageSelectedEnd"].CGColor, nil];

	
	// Initialize the gradient layer
    self.gl = [[CAGradientLayer alloc] init];
    // Set its bounds to be the same of its parent
	CGRect r = self.bounds;
	r.size.height += 200;
    [gl setBounds:r];
    // Center the layer inside the parent layer
    [gl setPosition:CGPointMake([self bounds].size.width/2, [self bounds].size.height/2)];
    // Insert the layer at position zero to make sure the 
    // text of the button is not obscured
    [[self layer] insertSublayer:gl atIndex:0];
	// Set the layer's corner radius
    [[self layer] setCornerRadius:18.0f];
    // Turn on masking
    [[self layer] setMasksToBounds:YES];
    // Display a border around the button 
    // with a 1.0 pixel width
//    [[self layer] setBorderWidth:1.0f];
	[gl setColors:self.normalColors];
	 self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
}

- (void)didMoveToSuperview
{
	CGRect r = CGRectInset([self frame], 8, 8);
	
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

-(void)setIsSelected:(BOOL)selected
{
	if (selected) {
		[gl setColors:self.selectedColors];
	} else {
		[gl setColors:self.normalColors];
	}
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