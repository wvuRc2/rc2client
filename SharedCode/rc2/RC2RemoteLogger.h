//
//  RC2RemoteLogger.h
//  iPadClient
//
//  Created by Mark Lilback on 9/25/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

@interface RC2RemoteLogger : DDAbstractLogger<DDLogger>
@property (nonatomic, retain) NSURL *logHost;
@property (nonatomic, retain) NSString *apiKey;
@property (nonatomic, retain) NSString *clientIdent;
@end
