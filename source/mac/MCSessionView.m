//
//  MCSessionView.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/3/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "MCSessionView.h"
#import "RCSavedSession.h"
#import "MAKVONotificationCenter.h"

const CGFloat kFrameWidth = 214;
const CGFloat kDefaultSplitPercent = 0.5;
NSString * const kAnimationKey = @"SessionAnimation";

@interface MacSessionEditView : NSView
@end

@interface MacSessionSplitter : NSView
@end

@interface MCSessionView()
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leftXConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *editorWidthConstraint;
@property (nonatomic, weak) IBOutlet MacSessionSplitter *splitterView;
@property (nonatomic, strong) NSTrackingArea *dragTrackingArea;
@property (nonatomic, readwrite) BOOL editorWidthLocked, leftViewAnimating;
@property (nonatomic) CGFloat splitterPercent;
@property (nonatomic) NSTimeInterval leftAnimLastUpdateTime;
@end

@implementation MCSessionView {
	BOOL _dragging;
}
- (id)init
{
	if ((self = [super init])) {
		self.splitterPercent = kDefaultSplitPercent;
	}
	return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	self.editorWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
	self.editorWidthConstraint.constant = 400;
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(toggleEditorWidthLock:)) {
		menuItem.state = self.editorWidthLocked ? NSOnState : NSOffState;
		return YES;
	}
	return [super validateMenuItem:menuItem];
}

-(void)saveSessionState:(RCSavedSession*)sessionState
{
	[sessionState setProperty:@(self.splitterPercent) forKey:@"editorWidthPercent"];
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	BOOL showLeft = [savedState boolPropertyForKey:@"fileListVisible"];
	CGFloat splitPer = [[savedState propertyForKey:@"editorWidthPercent"] doubleValue];
	if (splitPer < .1 || splitPer > .9) {
		splitPer = kDefaultSplitPercent;
		self.splitterPercent = splitPer;
	}
	CGFloat fullWidth = _outputView.frame.size.width + _editorView.frame.size.width;
	CGFloat ew = fullWidth * splitPer;
	self.splitterPercent = splitPer;
	if (!showLeft) {
		[self.leftXConstraint setConstant:-kFrameWidth];
		ew += kFrameWidth/2;
	}
	if (ew < 300)
		ew = 300;
	self.editorWidthConstraint.constant = ew;
}

-(void)adjustViewSizes
{
	[self adjustEditorWidth:self.splitterView.frame.origin.x - NSMinX(self.editorView.frame) + 1];
	[self.outputView setNeedsUpdateConstraints:YES];
}

-(CGFloat)computeEditorWidth
{
	CGFloat leftWidth = _leftView.frame.origin.x + kFrameWidth;
	CGFloat splittableWidth = self.frame.size.width - leftWidth - _splitterView.frame.size.width;
	CGFloat editWidth = splittableWidth * self.splitterPercent;
//	NSLog(@"lx=%1.0f, lw=%1.0f, sw=%1.0f, ew=%1.0f, sp=%1.2f", _leftView.frame.origin.x, leftWidth, splittableWidth, editWidth, self.splitterPercent);
	return editWidth;
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[super resizeSubviewsWithOldSize:oldSize];

	if (self.editorWidthLocked || _dragging || self.leftViewAnimating)
		return;

	CGFloat editWidth = [self computeEditorWidth];
	
	if (self.window.inLiveResize) {
		CGFloat delta = self.frame.size.width - oldSize.width;
		CGFloat editWidth = _editorView.frame.size.width + (delta / 2);
		//don't want animation
		self.editorWidthConstraint.constant = editWidth;
	} else {
		[self adjustEditorWidth:editWidth];
	}
}

-(void)mouseDown:(NSEvent*)evt
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
		self.splitterPercent = _editorView.frame.size.width / (_editorView.frame.size.width + _outputView.frame.size.width);
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
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[newView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(newView)]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[newView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(newView)]];
}

-(void)adjustEditorWidth:(CGFloat)editWidth
{
	self.editorWidthConstraint.animator.constant = editWidth;
//	CGFloat diff = fabs(self.editorWidthConstraint.constant - editWidth);
//	if (diff > 1.99) {
//		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
//			context.duration = 0.3;
//			NSLog(@"animating");
//			self.editorWidthConstraint.constant = editWidth;
//			CGFloat newX = NSMinX(self.leftView.frame) >= 0 ? -kFrameWidth : 0;
//			[[self.leftXConstraint animator] setConstant:newX];
//		} completionHandler:^{
//			
//		}];
//	}
}

-(IBAction)toggleEditorWidthLock:(id)sender
{
	self.editorWidthLocked = !self.editorWidthLocked;
}

-(IBAction)toggleLeftView:(id)sender
{
	CGFloat newX = NSMinX(self.leftView.frame) >= 0 ? -kFrameWidth : 0;
	//If we wanted to split the space, we could use the edit width constraint to reduce editor width

	CGFloat newWidth;
	if (newX < 0)
		newWidth = (self.frame.size.width - self.splitterView.frame.size.width) / 2;
	else
		newWidth = (self.frame.size.width - self.splitterView.frame.size.width - kFrameWidth) / 2;
	self.leftViewAnimating = YES;
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		context.duration = 0.3;
		if (!self.editorWidthLocked)
			self.editorWidthConstraint.animator.constant = newWidth;
		self.leftXConstraint.animator.constant = newX;
	} completionHandler:^{
		self.leftViewAnimating = NO;
	}];

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
		[self adjustEditorWidth:editorWidth];
//		[[self.editorWidthConstraint animator] setConstant:editorWidth];
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