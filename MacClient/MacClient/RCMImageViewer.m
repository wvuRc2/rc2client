//
//  RCMImageViewer.m
//  MacClient
//
//  Created by Mark Lilback on 10/17/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMImageViewer.h"
#import "RCImage.h"

@interface RCMImageViewer()
@property (strong) id observerToken;
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
		RCImage *img = [[blockSelf.imageArrayController selectedObjects] firstObject];
		blockSelf.displayedImageName = [NSString stringWithFormat:@"%@ (%ld of %ld)", img.name, 
								   [blockSelf.imageArrayController.arrangedObjects indexOfObject:img]+1,
								   [blockSelf.imageArrayController.arrangedObjects count]];
	}];
}

-(void)displayImage:(NSString*)path
{
	NSInteger idx = [self.imageArray indexOfObjectWithValue:path usingSelector:@selector(name)];
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
		NSData *data = [img.image pngData];
		[data writeToURL:[savePanel URL] atomically:YES];
	}];
}

@synthesize imageView;
@synthesize imageArray;
@synthesize imageArrayController;
@synthesize displayedImageName;
@synthesize observerToken;
@end
