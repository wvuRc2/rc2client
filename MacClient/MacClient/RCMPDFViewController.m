//
//  RCMPDFViewController.m
//  MacClient
//
//  Created by Mark Lilback on 11/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMPDFViewController.h"

@implementation RCMPDFViewController

-(id)init
{
	if ((self = [super initWithNibName:@"RCMPDFViewController" bundle:nil])) {
	}
	return self;
}

-(void)loadPdf:(NSString*)filePath
{
	PDFDocument *doc = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:filePath]];
	self.pdfView.document = doc;
}

@synthesize pdfView;
@end
