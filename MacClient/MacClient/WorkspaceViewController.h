//
//  WorkspaceViewController.h
//  MacClient
//
//  Created by Mark Lilback on 9/30/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacClientAbstractViewController.h"

@class RCWorkspace;

@interface WorkspaceViewController : MacClientAbstractViewController
@property (nonatomic, strong) RCWorkspace *workspace;
-(id)initWithWorkspace:(RCWorkspace*)aWorkspace;
@end
