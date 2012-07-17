//
//  RCWorkspaceShare.h
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;

@interface RCWorkspaceShare : NSObject
@property (nonatomic, strong) NSNumber *shareId;
@property (nonatomic, strong) RCWorkspace *workspace;
@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic) BOOL canOpenFiles;
@property (nonatomic) BOOL canWriteFiles;
@property (nonatomic) BOOL requiresOwner;

-(id)initWithDictionary:(NSDictionary*)dict workspace:(RCWorkspace*)wspace;
-(void)updateFromDictionary:(NSDictionary*)dict;

@end
