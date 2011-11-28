//
//  RCMPDFViewController.h
//  MacClient
//
//  Created by Mark Lilback on 11/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "MacClientAbstractViewController.h"

@interface RCMPDFViewController : MacClientAbstractViewController
@property (nonatomic, strong) IBOutlet PDFView *pdfView;

-(void)loadPdf:(NSString*)filePath;
@end
