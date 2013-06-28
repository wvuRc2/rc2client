//
//  RCDropboxSync.h
//  Rc2Client
//
//  Created by Mark Lilback on 6/21/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;
@protocol RCDropboxSyncDelegate;

@interface RCDropboxSync : NSObject
-(id)initWithWorkspace:(RCWorkspace*)wspace;

-(void)startSync;

@property (nonatomic, weak) id<RCDropboxSyncDelegate> syncDelegate;
@end


@protocol RCDropboxSyncDelegate <NSObject>
-(void)dbsync:(RCDropboxSync*)sync updateProgress:(CGFloat)percent message:(NSString*)message;
-(void)dbsync:(RCDropboxSync*)sync syncComplete:(BOOL)success error:(NSError*)error;
@end
