//
//  RCMPDFViewController.m
//  MacClient
//
//  Created by Mark Lilback on 11/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMPDFViewController.h"
#import "RCFile.h"

@interface RCMPDFViewController()
@property (nonatomic, strong) RCFile *theFile;
-(void)handlePdfNotification:(NSNotification*)note;
@end

@implementation RCMPDFViewController

-(id)init
{
	if ((self = [super initWithNibName:@"RCMPDFViewController" bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handlePdfNotification:) name:PDFViewDisplayModeChangedNotification object:self.pdfView];
}
		 
-(void)loadPdf:(NSString*)filePath
{
	PDFDocument *doc = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:filePath]];
	self.pdfView.document = doc;
}

-(void)loadPdfFile:(RCFile*)file
{
	self.theFile = file;
	[self loadPdf:file.fileContentsPath];
	//setup display mode
	PDFDisplayMode mode = kPDFDisplaySinglePage;
	NSNumber *modeObj = [file.localAttrs objectForKey:@"PDFDisplayMode"];
	if (modeObj)
		mode = [modeObj integerValue];
	[self.pdfView setDisplayMode:mode];
}

-(void)handlePdfNotification:(NSNotification*)note
{
	if ([[note name] isEqualToString:PDFViewDisplayModeChangedNotification]) {
		NSMutableDictionary *attrs = self.theFile.localAttrs;
		[attrs setObject:[NSNumber numberWithInteger:self.pdfView.displayMode] forKey:@"PDFDisplayMode"];
		self.theFile.localAttrs = attrs;
	}
}

@synthesize pdfView;
@synthesize theFile;
@end
