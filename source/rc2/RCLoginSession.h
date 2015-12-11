//
//  RCLoginSession.h
//  Rc2Client
//
//  Created by Mark Lilback on 12/10/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Rc2User;
@class Rc2Workspace;

@interface RCLoginSession : NSObject
@property (nonatomic, copy) NSArray<Rc2Workspace*> *workspaces;
@property (nonatomic, strong, readonly) Rc2User *currentUser;
@property (nonatomic, copy, readonly) NSString *authToken;

-(instancetype)initWithJsonData:(NSDictionary*)json;

@end
