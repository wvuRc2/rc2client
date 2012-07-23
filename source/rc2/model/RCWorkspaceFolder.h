//
//  RCWorkspaceFolder.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCWorkspaceItem.h"

@interface RCWorkspaceFolder : RCWorkspaceItem 
@property (weak, nonatomic, readonly) NSArray *children;

//goes recursive through child folders
-(RCWorkspaceItem*)childWithId:(NSNumber*)theId;

-(void)addChild:(RCWorkspaceItem*)aChild;
-(void)removeChild:(RCWorkspaceItem*)aChild;
@end