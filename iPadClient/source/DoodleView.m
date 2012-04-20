//
//  DoodleView.m
//  iPadClient
//
//  Created by Mark Lilback on 4/20/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "DoodleView.h"

@interface DoodleView()
@property (nonatomic, strong) NSMutableArray *paths;
@property (nonatomic, assign) CGMutablePathRef currentPath;
@end

@implementation DoodleView

-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	self.paths = [NSMutableArray array];
//	self.backgroundColor = [[UIColor magentaColor] colorWithAlphaComponent:0.05];
	self.backgroundColor = [UIColor clearColor];
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clearDoodles:)];
	tap.numberOfTapsRequired = 2;
	[self addGestureRecognizer:tap];
	return self;
}

-(void)clearDoodles:(id)sender
{
	[self.paths removeAllObjects];
	[self setNeedsDisplay];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint pt = [touches.anyObject locationInView:self];
	self.currentPath = CGPathCreateMutable();
	[self.paths addObject:(__bridge id)self.currentPath];
	CGPathMoveToPoint(self.currentPath, &CGAffineTransformIdentity, pt.x, pt.y);
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint pt = [touches.anyObject locationInView:self];
	CGPathAddLineToPoint(self.currentPath, &CGAffineTransformIdentity, pt.x, pt.y);
	[self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.currentPath=nil;
	[self setNeedsDisplay];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.currentPath=nil;
	[self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
	CGContextSetLineWidth(ctx, 4.0);
	for (id aPathObj in self.paths) {
		CGPathRef path = (__bridge CGPathRef)aPathObj;
		CGContextAddPath(ctx, path);
	}
	CGContextStrokePath(ctx);
}

@synthesize currentPath;
@synthesize paths=_paths;
@end
