//
//  RCActiveLogin.h
//  Rc2Client
//
//  Created by Mark Lilback on 7/31/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCUser;

@interface RCActiveLogin : NSObject
@property (nonatomic, copy) NSArray *projects;
@property (nonatomic, strong, readonly) RCUser *currentUser;
@property (nonatomic, readonly) NSString *connectionDescription; //login name plus host if host is not rc2
@property (nonatomic, readonly) BOOL isAdmin;
@property (nonatomic, copy, readonly) NSArray *usersPermissions;
@property (nonatomic, copy, readonly) NSArray *ldapServers;
@property (nonatomic, copy, readonly) NSArray *classesTaught;
@property (nonatomic, copy, readonly) NSArray *assignmentsToGrade;
@property (nonatomic, strong, readonly) NSArray *messageRecipients;

-(instancetype)initWithJsonData:(NSDictionary*)json;
@end
