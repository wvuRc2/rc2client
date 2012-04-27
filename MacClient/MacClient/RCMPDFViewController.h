//
//  RCMPDFViewController.h
//  MacClient
//
//  Created by Mark Lilback on 11/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "MacClientAbstractViewController.h"

@class RCFile;

@interface RCMPDFViewController : MacClientAbstractViewController
@property (nonatomic, strong) IBOutlet PDFView *pdfView;

-(void)loadPdfFile:(RCFile*)file;
-(void)loadPdf:(NSString*)filePath;
@end
