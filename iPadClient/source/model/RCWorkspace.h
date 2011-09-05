//
//  RCWorkspace.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCWorkspaceItem.h"

@class RCFile;

@interface RCWorkspace : RCWorkspaceItem
@property (nonatomic, copy, readonly) NSArray *files;
-(void)refreshFiles;

-(void)addFile:(RCFile*)aFile;
-(RCFile*)fileWithId:(NSNumber*)fileId;
@end
