//
//  MacSessionView.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/3/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "MacSessionView.h"

@interface MacSessionEditView : NSView
@end

@interface MacSessionSplitter : NSView
@end

@interface MacSessionView()
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leftXConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *editorWidthConstraint;
@property (nonatomic, weak) IBOutlet MacSessionSplitter *splitterView;
@end

@implementation MacSessionView {
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
}

-(void)mouseDown:(NSEvent *)evt
{
	NSPoint loc = [self convertPoint:evt.locationInWindow fromView:nil];
	if (NSPointInRect(loc, self.splitterView.frame)) {
		_dragging = YES;
	}
}

-(void)mouseDragged:(NSEvent *)evt
{
	if (_dragging) {
		NSPoint loc = [self convertPoint:evt.locationInWindow fromView:nil];
		CGFloat newWidth = loc.x - NSMinX(self.editorView.frame);
		if (newWidth > 100) {
			self.editorWidthConstraint.constant = newWidth;
		}
	}
}

-(void)mouseUp:(NSEvent *)evt
{
	if (_dragging) {
		_dragging = NO;
	}
}

-(void)embedOutputView:(NSView *)newView
{
	newView.frame = self.outputView.bounds;
	[self.outputView addSubview:newView];
	NSDictionary *dict = NSDictionaryOfVariableBindings(newView);
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[newView]-0-|" options:0 metrics:nil views:dict]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[newView]-0-|" options:0 metrics:nil views:dict]];
}

-(IBAction)toggleLeftView:(id)sender
{
	CGFloat newX = NSMinX(self.leftView.frame) >= 0 ? -171 : 0;
	[[self.leftXConstraint animator] setConstant:newX];
}

-(CGFloat)editorWidth
{
	return self.editorWidthConstraint.constant;
}

-(void)setEditorWidth:(CGFloat)editorWidth
{
	if (editorWidth > 100)
		[[self.editorWidthConstraint animator] setConstant:editorWidth];
}

@end


@implementation MacSessionSplitter
-(void)awakeFromNib
{
	self.wantsLayer = YES;
	NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingCursorUpdate|NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow owner:self userInfo:nil];
	[self addTrackingArea:ta];
//	self.layer.backgroundColor = [NSColor blackColor].CGColor;
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