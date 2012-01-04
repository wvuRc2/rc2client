//
//  MultiFileImporter.h
//  MacClient
//
//  Created by Mark Lilback on 1/4/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;

@interface MultiFileImporter : NSOperation
@property (nonatomic, strong) RCWorkspace *workspace;
@property (assign) BOOL replaceExisting;
@property (nonatomic, copy) NSArray *fileUrls;
@property (nonatomic, readonly) NSInteger countOfFilesRemaining;
//while executing, someone can observe this to know what the current file being uploaded is.
@property (nonatomic, copy) NSString *currentFileName;
@end
