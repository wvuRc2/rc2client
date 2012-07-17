//
//  MultiFileImporter.h
//  MacClient
//
//  Created by Mark Lilback on 1/4/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;

@interface MultiFileImporter : NSOperation

//convience methods for drag & drop of files into an NSTableView
+(NSDragOperation)validateTableViewFileDrop:(id <NSDraggingInfo>)info;
//determines what files to import, prompting the user if necessary to see if existing files should be replaced or unique names should be
// generated. Unless the user cancels, handler will be called with the actual files to import. Ideally they should then be passed
// to an instance of MultiFileImporter.
+(void)acceptTableViewFileDrop:(NSTableView *)tableView dragInfo:(id <NSDraggingInfo>)info existingFiles:(NSArray*)existingFiles
			 completionHandler:(void (^)(NSArray *urls, BOOL replaceExisting))handler;

//generates a unique name "file X" for the specified file
+(NSString*)uniqueFileName:(NSString*)fname existingFiles:(NSArray*)existingFiles;

@property (nonatomic, strong) RCWorkspace *workspace;
@property (assign) BOOL replaceExisting;
@property (nonatomic, copy) NSArray *fileUrls;
@property (nonatomic, readonly) NSInteger countOfFilesRemaining;
@property (nonatomic, strong) NSError *lastError; //on an error, this is set and the import process stops
//while executing, someone can observe this to know what the current file being uploaded is.
@property (nonatomic, copy) NSString *currentFileName;

//sets up a progress window. The caller just needs to display the progress window and handle an error message. The argument to the
// error handler is the MultiFileImporter
-(AMProgressWindowController*)prepareProgressWindowWithErrorHandler:(BasicBlock1Arg)errorHandler;
@end
