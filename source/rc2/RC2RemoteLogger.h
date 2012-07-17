//
//  RC2RemoteLogger.h
//  iPadClient
//
//  Created by Mark Lilback on 9/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

@interface RC2RemoteLogger : DDAbstractLogger<DDLogger>
@property (nonatomic, strong) NSURL *logHost;
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *clientIdent;
@end
