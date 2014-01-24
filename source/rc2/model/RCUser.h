//
//  RCUser.h
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCUser : NSObject
@property (nonatomic, strong, readonly) NSNumber *userId;
@property (nonatomic, copy) NSString *login;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *firstname;
@property (nonatomic, copy) NSString *lastname;
@property (nonatomic, readonly) NSString *fullName;
@property (nonatomic, copy) NSString *ldapLogin;
@property (nonatomic, strong) NSNumber *ldapServerId;
@property (nonatomic, copy) NSString *smsphone;
@property (nonatomic, copy) NSString *twitter;
@property (nonatomic, copy) NSArray *roleIds;
@property (nonatomic, copy) NSArray *roles;
@property (nonatomic, assign) BOOL notesByEmail;
@property (nonatomic, readonly) BOOL isDirty;
@property (nonatomic, readonly) BOOL existsOnServer;
@property (nonatomic) BOOL isAdmin;

-(id)initWithDictionary:(NSDictionary*)dict allRoles:(NSArray*)allRoles;
@end
