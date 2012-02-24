//
//  RCMImagePrintView.m
//  MacClient
//
//  Created by Mark Lilback on 10/18/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMImagePrintView.h"
#import "RCImage.h"

@interface RCMImagePrintView() {
	NSInteger __curPageNum;
}
@property (nonatomic, copy) NSString *dateString;
@end

@implementation RCMImagePrintView

- (id)initWithImages:(NSArray*)imgs;
{
	if ((self = [super initWithFrame:NSMakeRect(0, 0, 480, 480)])) {
		self.images = imgs;
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		df.timeStyle = NSDateFormatterShortStyle;
		df.dateStyle = NSDateFormatterMediumStyle;
		self.dateString = [df stringFromDate:[NSDate date]];
	}
	return self;
}

-(BOOL)knowsPageRange:(NSRangePointer)range
{
	range->location=1;
	range->length=[self.images count];
	return YES;
}

-(NSRect)rectForPage:(NSInteger)page
{
	return NSMakeRect(page, page, self.bounds.size.width, self.bounds.size.height);
}

-(void)beginPageInRect:(NSRect)aRect atPlacement:(NSPoint)location
{
	__curPageNum = aRect.origin.x;
	[super beginPageInRect:self.bounds atPlacement:location];
}

-(void)drawPageBorderWithSize:(NSSize)borderSize
{
	//default margins are too crazy on size. we're hardcoding our own
	CGFloat vertMargin = 36;
	CGFloat horzMargin = 36;
	NSRect oldFrame = self.frame;
	self.frame = NSMakeRect(0, 0, borderSize.width, borderSize.height);
	[self lockFocus];
	NSString *str = [NSString stringWithFormat:@"Rc²: %@", [[NSPrintOperation currentOperation] jobTitle]];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
	NSSize strSz = [str sizeWithAttributes:dict];
	NSPoint pt = NSMakePoint(horzMargin, borderSize.height-vertMargin-strSz.height);
	[str drawAtPoint:pt withAttributes:dict];
	str = [NSString stringWithFormat:@"Page %ld of %ld", __curPageNum, self.images.count];
	strSz = [str sizeWithAttributes:dict];
	pt.x = borderSize.width - horzMargin - strSz.width;
	[str drawAtPoint:pt withAttributes:dict];
	//footer
	strSz = [self.dateString sizeWithAttributes:dict];
	pt.x = borderSize.width - horzMargin - strSz.width;
	pt.y = 36;
	[self.dateString drawAtPoint:pt withAttributes:dict];
	str = [[self.images objectAtIndex:__curPageNum-1] name];
	strSz = [str sizeWithAttributes:dict];
	pt.x = horzMargin;
	[str drawAtPoint:pt withAttributes:dict];
	[self unlockFocus];
	self.frame = oldFrame;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([NSGraphicsContext currentContextDrawingToScreen]) {
		return;
	}
	RCImage *rcimg = [self.images objectAtIndex:__curPageNum-1];
	NSImage *img = [rcimg image];
	NSLog(@"f=%@, b=%@, dr=%@", NSStringFromRect(self.frame), NSStringFromRect(self.bounds), NSStringFromRect(dirtyRect));
	[img drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

@synthesize images;
@synthesize dateString;
@end
