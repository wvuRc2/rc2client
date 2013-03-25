//
//  PasswordVerifier.h
//  MacClient
//
//  Created by Mark Lilback on 10/29/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PasswordVerifier : NSObject
//bind password1 and password2 to the two password fields with continuously update value
@property (nonatomic, copy) NSString *password1;
@property (nonatomic, copy) NSString *password2;
//a message to display
@property (nonatomic, copy) NSString *warningMessage;
//YES if the two passwords match and follow rules
@property (nonatomic) BOOL isValid;
//YES if there is a warning message. No warning message is displayed when there is nothing
// in one of the password fields, assuming user has not typed in those fields yet so there
// is no reason to show a warning even though not valid
@property (nonatomic, readonly) BOOL hasWarningMessage;
@property (nonatomic, strong) NSNumber *minLength;
@property (nonatomic, strong) NSNumber *maxLength;
@property (nonatomic, copy) NSCharacterSet *validCharacterSet;
//if not enabled, always returns true for isValid
@property (nonatomic, assign) BOOL enabled;
@end
