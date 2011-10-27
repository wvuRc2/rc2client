//
//  RCWorkspaceShare.h
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;

@interface RCWorkspaceShare : NSObject
@property (nonatomic, strong) NSNumber *shareId;
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
@property (nonatomic, weak) RCWorkspace *workspace;
#else
@property (nonatomic, assign) RCWorkspace *workspace;
#endif
@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic) BOOL canOpenFiles;
@property (nonatomic) BOOL canWriteFiles;
@property (nonatomic) BOOL requiresOwner;

-(id)initWithDictionary:(NSDictionary*)dict workspace:(RCWorkspace*)wspace;
-(void)updateFromDictionary:(NSDictionary*)dict;

@end
