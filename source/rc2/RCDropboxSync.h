//
//  RCDropboxSync.h
//  Rc2Client
//
//  Created by Mark Lilback on 6/21/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;

@interface RCDropboxSync : NSObject
-(id)initWithWorkspace:(RCWorkspace*)wspace;

-(void)startSync;

@property (nonatomic, copy) void (^progressHandler)(CGFloat percent, NSString *message);
@property (nonatomic, copy) void (^completionHandler)(BOOL success, NSError *error);
@end
