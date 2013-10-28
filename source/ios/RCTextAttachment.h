//
//  RCTextAttachment.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/28/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCTextAttachment : NSTextAttachment
@end

@interface RCFileAttachment : RCTextAttachment
@property (nonatomic, strong) NSNumber *fileId;
@property (nonatomic, copy) NSString *fileName;
@end

@interface RCImageAttachment : RCTextAttachment
@property (nonatomic, strong) NSNumber *imageId;
@property (nonatomic, copy) NSString *imageUrl;
@end

