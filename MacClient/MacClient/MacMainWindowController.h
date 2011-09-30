//
//  MacMainWindowController.h
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXSourceList.h"

@interface MacMainWindowController : NSWindowController<PXSourceListDataSource,PXSourceListDelegate>
@property (strong) IBOutlet PXSourceList *mainSourceList;
@property (strong) IBOutlet NSView *detailView;
@end
