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
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *roleIds;
@property (nonatomic, copy) NSArray *roles;
@property (nonatomic, readonly) BOOL isDirty;
@property (nonatomic, readonly) BOOL existsOnServer;
@property (nonatomic) BOOL isAdmin;

-(id)initWithDictionary:(NSDictionary*)dict allRoles:(NSArray*)allRoles;
@end
