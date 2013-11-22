//
//  MCSessionView.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/3/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "MCSessionView.h"
#import "RCSavedSession.h"

const CGFloat kFrameWidth = 214;

@interface MacSessionEditView : NSView
@end

@interface MacSessionSplitter : NSView
@end

@interface MCSessionView()
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leftXConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *editorWidthConstraint;
@property (nonatomic, weak) IBOutlet MacSessionSplitter *splitterView;
@property (nonatomic, strong) NSTrackingArea *dragTrackingArea;
@end

@implementation MCSessionView {
	BOOL _dragging;
}
- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	self.editorWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
	self.editorWidthConstraint.constant = 400;
	CABasicAnimation *anim = [CABasicAnimation animation];
	anim.delegate = self;
	[self.leftXConstraint setAnimations:@{@"constant": anim}];
}

-(void)saveSessionState:(RCSavedSession*)sessionState
{
	CGFloat fullWidth = _outputView.frame.size.width + _editorView.frame.size.width;
	CGFloat splitPer = _editorView.frame.size.width / fullWidth;
	[sessionState setProperty:@(splitPer) forKey:@"editorWidthPercent"];
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	BOOL showLeft = [savedState boolPropertyForKey:@"fileListVisible"];
	CGFloat splitPer = [[savedState propertyForKey:@"editorWidthPercent"] doubleValue];
	CGFloat fullWidth = _outputView.frame.size.width + _editorView.frame.size.width;
	CGFloat ew = fullWidth * splitPer;
	if (!showLeft) {
		[self.leftXConstraint setConstant:-kFrameWidth];
		ew += kFrameWidth/2;
	}
	if (ew < 300)
		ew = 300;
	self.editorWidthConstraint.constant = ew;
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	CGFloat editorWidth = 0;
	CGFloat newWidth = self.frame.size.width;
	if (newWidth != oldSize.width && oldSize.width > 0) {
		CGFloat perChange = self.frame.size.width / oldSize.width;
		editorWidth = _editorView.frame.size.width * perChange;
	}
	[super resizeSubviewsWithOldSize:oldSize];
	if (editorWidth > 0)
		self.editorWidthConstraint.constant = editorWidth;
}

-(void)mouseDown:(NSEvent *)evt
{
	NSPoint loc = [self convertPoint:evt.locationInWindow fromView:nil];
	NSRect f = NSInsetRect(self.splitterView.frame, -2, 0);
	if (NSPointInRect(loc, f)) {
		_dragging = YES;
		self.dragTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingCursorUpdate|NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow owner:self userInfo:nil];
		[self addTrackingArea:self.dragTrackingArea];

	}
}

-(void)mouseDragged:(NSEvent *)evt
{
	if (_dragging) {
		NSPoint loc = [self convertPoint:evt.locationInWindow fromView:nil];
		CGFloat newWidth = loc.x - NSMinX(self.editorView.frame);
		if (newWidth >= 300) {
			self.editorWidthConstraint.constant = newWidth;
		}
	}
}

-(void)mouseUp:(NSEvent *)evt
{
	if (_dragging) {
		_dragging = NO;
		[self removeTrackingArea:self.dragTrackingArea];
		self.dragTrackingArea=nil;
	}
}

-(void)cursorUpdate:(NSEvent *)event
{
	if (self.dragTrackingArea) {
		[[NSCursor resizeLeftRightCursor] set];
	}
}

-(void)embedOutputView:(NSView *)newView
{
	newView.frame = self.outputView.bounds;
	[self.outputView addSubview:newView];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:newView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.outputView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:newView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.outputView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
	if (flag) {
		//even though the animation is reported stopped, the left view was still at -17 instead of 0.
		// so we impose a delay to make sure it is back to zero
		RunAfterDelay(0.1, ^{
			[self willChangeValueForKey:@"leftViewVisible"];
			[self didChangeValueForKey:@"leftViewVisible"];
		});
	}
}

-(IBAction)toggleLeftView:(id)sender
{
	CGFloat newX = NSMinX(self.leftView.frame) >= 0 ? -kFrameWidth : 0;
	[[self.leftXConstraint animator] setConstant:newX];
	//If we wanted to split the space, we could use the edit width constraint to reduce editor width
}

-(BOOL)leftViewVisible
{
	return NSMinX(self.leftView.frame) >= 0;
}

-(CGFloat)editorWidth
{
	return self.editorWidthConstraint.constant;
}

-(void)setEditorWidth:(CGFloat)editorWidth
{
	if (editorWidth > 100) {
		[[self.editorWidthConstraint animator] setConstant:editorWidth];
	}
}

@end


@implementation MacSessionSplitter
-(void)awakeFromNib
{
	self.wantsLayer = YES;
	NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingCursorUpdate|NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow owner:self userInfo:nil];
	[self addTrackingArea:ta];
}

-(void)drawRect:(NSRect)dirtyRect
{
	NSRect dark = self.bounds, light = self.bounds;
	dark.size.width -= 2;
	light.size.width = 2;
	light.origin.x += dark.size.width;
	[[NSColor darkGrayColor] set];
	NSRectFill(dark);
	[[NSColor whiteColor] set];
	NSRectFill(light);
}

-(void)cursorUpdate:(NSEvent *)event
{
	[[NSCursor resizeLeftRightCursor] set];
}

@end

@implementation MacSessionEditView
@end