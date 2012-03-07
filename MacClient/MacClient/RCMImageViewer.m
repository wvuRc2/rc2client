//
//  RCMImageViewer.m
//  MacClient
//
//  Created by Mark Lilback on 10/17/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMImageViewer.h"
#import "RCMImagePrintView.h"
#import "RCImage.h"
#import "RCWorkspace.h"

@interface RCMImageViewer()
@property (strong) id observerToken;
@property (strong) NSMutableDictionary *twoFingersTouches;
@end

@implementation RCMImageViewer

- (id)init
{
	if ((self = [super initWithNibName:@"RCMImageViewer" bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	self.imageView.allowsCutCopyPaste = YES;
	__unsafe_unretained RCMImageViewer *blockSelf = self;
	self.observerToken = [self.imageArrayController addObserverForKeyPath:@"selection" task:^(id obj, NSDictionary *change)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			RCImage *img = [[blockSelf.imageArrayController selectedObjects] firstObject];
			blockSelf.displayedImageName = [NSString stringWithFormat:@"%@ (%ld of %ld)", img.name, 
									   [blockSelf.imageArrayController.arrangedObjects indexOfObject:img]+1,
									   [blockSelf.imageArrayController.arrangedObjects count]];
		});
	}];
}

-(void)displayImage:(NSNumber*)imageId
{
	NSInteger idx = [self.imageArray indexOfFirstObjectWithValue:imageId forKey:@"imageId"];
	if (idx < 0 || idx > self.imageArray.count)
		idx = 0;
	[self.imageArrayController setSelectionIndex:idx];
}

-(IBAction)saveImageAs:(id)sender
{
	RCImage *img = [self.imageArrayController.arrangedObjects objectAtIndex:self.imageArrayController.selectionIndex];
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"png"]];
	[savePanel setNameFieldStringValue:img.name];
	[savePanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSData *data = [img.image pngData];
			[data writeToURL:[savePanel URL] atomically:YES];
		}
	}];
}

-(void)goBack
{
	if (self.imageArrayController.canSelectPrevious)
		[self.imageArrayController selectPrevious:self];
}

-(void)goForward
{
	if (self.imageArrayController.canSelectNext)
		[self.imageArrayController selectNext:self];
}

-(IBAction)showImageDetails:(id)sender
{
	self.detailsBlock();
}


#define kSwipeMinimumLength 0.3

@synthesize twoFingersTouches;

// Three fingers gesture, Lion (if enabled) and Leopard
- (void)swipeWithEvent:(NSEvent *)event
{
    CGFloat x = [event deltaX];
    //CGFloat y = [event deltaY];
    
    if (x != 0) {
		(x > 0) ? [self goBack] : [self goForward];
	}
}

- (void)beginGestureWithEvent:(NSEvent *)event
{
	//TODO: technically, we need to figure out if swipe navigation is enabled in system prefs
	
	NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:nil];
	
	self.twoFingersTouches = [[NSMutableDictionary alloc] init];
	
	for (NSTouch *touch in touches) {
		[twoFingersTouches setObject:touch forKey:touch.identity];
	}
}

- (void)endGestureWithEvent:(NSEvent *)event
{
	if (!twoFingersTouches) return;
	
	NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:nil];
	
	// release twoFingersTouches early
	NSMutableDictionary *beginTouches = [twoFingersTouches copy];
	self.twoFingersTouches = nil;
	
	NSMutableArray *magnitudes = [[NSMutableArray alloc] init];
	
	for (NSTouch *touch in touches) 
	{
		NSTouch *beginTouch = [beginTouches objectForKey:touch.identity];
		
		if (!beginTouch) continue;
		
		float magnitude = touch.normalizedPosition.x - beginTouch.normalizedPosition.x;
		[magnitudes addObject:[NSNumber numberWithFloat:magnitude]];
	}
	
	// Need at least two points
	if ([magnitudes count] < 2) return;
	
	float sum = 0;
	
	for (NSNumber *magnitude in magnitudes)
		sum += [magnitude floatValue];
	
	// Handle natural direction in Lion
	BOOL naturalDirectionEnabled = [[[NSUserDefaults standardUserDefaults] valueForKey:@"com.apple.swipescrolldirection"] boolValue];
	
	if (naturalDirectionEnabled)
		sum *= -1;
	
	// See if absolute sum is long enough to be considered a complete gesture
	float absoluteSum = fabsf(sum);
	
	if (absoluteSum < kSwipeMinimumLength) return;
	
	// Handle the actual swipe
	if (sum > 0) 
	{
		[self goForward];
	} else
	{
		[self goBack];
	}
}

-(BOOL)shouldHandlePrintCommand:(id)sender
{
	RCMImagePrintView *printView = [[RCMImagePrintView alloc] initWithImages:self.imageArray];
	NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:printView];
	printOp.jobTitle = self.workspace.name;
	[printOp runOperation];
	return NO;
}

@synthesize imageView;
@synthesize imageArray;
@synthesize imageArrayController;
@synthesize displayedImageName;
@synthesize observerToken;
@synthesize workspace;
@synthesize detailsBlock;
@end
