//
//  RCFileContainer.h
//  Rc2Client
//
//  Created by Mark Lilback on 12/6/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCFile;

extern NSString * const RCFileContainerChangedNotification;

@protocol RCFileContainer <NSObject>
-(NSNumber*)projectId;

-(NSString*)fileCachePath;

-(NSArray*)files;

//only to be called by Rc2Server when server notifies or after an import/create
-(void)addFile:(RCFile*)aFile;
@end
