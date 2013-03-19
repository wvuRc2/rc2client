//
//  RCWorkspace.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCFileContainer.h"

@class RCProject;
@class RCFile;
@class RCWorkspaceCache;

@interface RCWorkspace : NSObject <RCFileContainer>
@property (nonatomic, weak) RCProject *project;
@property (nonatomic, strong) NSNumber *wspaceId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDate *lastAccess;

@property (nonatomic, copy, readonly) NSArray *files;
@property (nonatomic, readonly) RCWorkspaceCache *cache;
@property (nonatomic) BOOL updateFileContentsOnNextFetch; //if set to YES, will async grab contents of any empty or modified files
@property (readonly) BOOL isFetchingFiles;

//just calls through to parent project. useful for file operations where a project or workspace can be passed as an argument
@property (readonly) NSNumber *projectId;

-(id)initWithDictionary:(NSDictionary*)dict;


-(void)refreshFiles;

-(void)addFile:(RCFile*)aFile;
-(RCFile*)fileWithId:(NSNumber*)fileId;
-(RCFile*)fileWithName:(NSString*)fileName;

//for others to tell the workspace that a file was added or updated
-(void)updateFileId:(NSNumber*)fileId;

@end
