//
//  RCFileContainer.h
//  Rc2Client
//
//  Created by Mark Lilback on 12/6/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCFile;

@protocol RCFileContainer <NSObject>
-(NSNumber*)projectId;
-(void)addFile:(RCFile*)aFile;
@end
