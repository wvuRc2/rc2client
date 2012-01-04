//
//  MultiFileImporter.m
//  MacClient
//
//  Created by Mark Lilback on 1/4/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "MultiFileImporter.h"
#import "Rc2Server.h"
#import "RCWorkspace.h"
#import "RCFile.h"

enum {
	kState_Ready=0,
	kState_Running,
	kState_Done
};

@interface MultiFileImporter()
@property (atomic) NSInteger myState;
@property (strong) NSMutableSet *filesRemaining;
-(void)markAsComplete;
@end

@implementation MultiFileImporter

-(void)importFile:(NSURL*)fileUrl
{
	NSString *destFileName = fileUrl.lastPathComponent;
	RCFile *existingFile = [self.workspace fileWithName:fileUrl.lastPathComponent];
	if (existingFile) {
		if (self.replaceExisting) {
			//FIXME: need to do something special here
			return;
		} else {
			//need to generate a unique file name
			NSInteger i=1;
			while (YES) {
				NSString *newName = [NSString stringWithFormat:@"%@ %ld.%@", [destFileName stringByDeletingPathExtension],
									 i++, [destFileName pathExtension]];
				if (nil == [self.workspace fileWithName:newName]) {
					destFileName = newName;
					break;
				}
			}
		}
	}
	self.currentFileName = destFileName;
	//we need to synchronously upload the file using the name destfileName
}

-(void)importNextFile
{
	if (self.isCancelled || self.filesRemaining.count < 1) {
		[self markAsComplete];
		return;
	}
	NSURL *theUrl = [self.filesRemaining anyObject];
	[self.filesRemaining removeObject:theUrl];
	[self importFile:theUrl];
	Rc2LogInfo(@"MFI imported %@", self.currentFileName);
	//finish up
	if ([self.filesRemaining count] > 0) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self importNextFile];
		});
	} else {
		[self markAsComplete];
	}
}

-(void)start
{
	self.filesRemaining = [NSMutableSet setWithArray:self.fileUrls];
	[self willChangeValueForKey:@"isExecuting"];
	self.myState = kState_Running;
	[self didChangeValueForKey:@"isExecuting"];
	if (self.isCancelled)
		[self markAsComplete];
	else
		[self importNextFile];
	
}

-(void)markAsComplete
{
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	self.myState = kState_Done;
	[self didChangeValueForKey:@"isFinished"];
	[self didChangeValueForKey:@"isExecuting"];
}

-(BOOL)isConcurrent { return YES; }

-(BOOL)isExecuting
{
	return self.myState == kState_Running;
}

-(BOOL)isFinished
{
	return self.myState == kState_Done;
}

-(NSInteger)countOfFilesRemaining
{
	return [self.filesRemaining count];
}

@synthesize fileUrls;
@synthesize myState;
@synthesize filesRemaining;
@synthesize replaceExisting;
@synthesize workspace;
@synthesize currentFileName;
@end
