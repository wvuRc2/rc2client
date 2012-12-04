//
//  MultiFileImporter.m
//  MacClient
//
//  Created by Mark Lilback on 1/4/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
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

+(NSDragOperation)validateTableViewFileDrop:(id <NSDraggingInfo>)info
{
	static NSDictionary *readOptions=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		readOptions = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey,
					   ARRAY((id)kUTTypePlainText,(id)kUTTypePDF), NSPasteboardURLReadingContentsConformToTypesKey,
					   nil];
	});
	NSArray *urls = [[info draggingPasteboard] readObjectsForClasses:ARRAY([NSURL class]) options:readOptions];
	if ([urls count] > 0) {
		NSArray *ftypes = [Rc2Server acceptableImportFileSuffixes];
		for (NSURL *url in urls) {
			if (![ftypes containsObject:[url pathExtension]])
				return NSDragOperationNone;
		}
		return NSDragOperationCopy;
	}
	return NSDragOperationNone;
}

//determines what files to import, prompting the user if necessary to see if existing files should be replaced or unique names should be
// generated. Unless the user cancels, handler will be called with the actual files to import. Ideally they should then be passed
// to an instance of MultiFileImporter.
+(void)acceptTableViewFileDrop:(NSTableView *)tableView dragInfo:(id <NSDraggingInfo>)info existingFiles:(NSArray*)existingFiles
	completionHandler:(void (^)(NSArray *urls, BOOL replaceExisting))handler
{
	//our validate method already confirmed they are acceptable file types
	NSArray *urls = [[info draggingPasteboard] readObjectsForClasses:ARRAY([NSURL class]) options:nil];
	//look for duplicate names
	NSArray *existingNames = [existingFiles valueForKey:@"name"];
	BOOL promptForAction=NO;
	for (NSURL *url in urls) {
		if ([existingNames containsObject:url.lastPathComponent])
			promptForAction = YES;
	}
	if (promptForAction) {
		//need to prompt them to replace or use unique names
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = @"Replace existing files?";
		alert.informativeText = @"One or more files already exist with the same name as the dropped file(s).";
		[alert addButtonWithTitle:@"Replace"];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
		NSButton *uniqButton = [alert addButtonWithTitle:@"Create Unique Names"];
		[uniqButton setKeyEquivalent:@"u"];
		[uniqButton setKeyEquivalentModifierMask:NSCommandKeyMask];
		[alert beginSheetModalForWindow:tableView.window completionHandler:^(NSAlert *theAlert, NSInteger btxIdx) {
			if (NSAlertSecondButtonReturn != btxIdx) {
				handler(urls, btxIdx == NSAlertFirstButtonReturn);
			}
		}];
	} else {
		handler(urls, YES);
	}
}

+(NSString*)uniqueFileName:(NSString*)fname existingFiles:(NSArray*)existingFiles
{
	NSInteger i=1;
	NSString *destFileName = fname;
	while (YES) {
		NSString *newName = [NSString stringWithFormat:@"%@ %ld.%@", [destFileName stringByDeletingPathExtension],
							 i++, [destFileName pathExtension]];
		if (nil == [existingFiles firstObjectWithValue:newName forKey:@"name"]) {
			destFileName = newName;
			break;
		}
	}
	return destFileName;
}

-(AMProgressWindowController*)prepareProgressWindowWithErrorHandler:(BasicBlock1Arg)errorHandler
{
	AMProgressWindowController *pwc = [[AMProgressWindowController alloc] init];
	pwc.progressMessage = @"Importing files…";
	pwc.indeterminate = NO;
	pwc.percentComplete = 0;
	__weak MultiFileImporter *weakMfi = self;
	NSString *perToken = [self addObserverForKeyPath:@"currentFileName" task:^(id obj, NSDictionary *change) {
		dispatch_async(dispatch_get_main_queue(), ^{
			pwc.progressMessage = [NSString stringWithFormat:@"Importing %@", [obj valueForKey:@"currentFileName"]];
			pwc.percentComplete = (1.0 - (weakMfi.countOfFilesRemaining / (CGFloat)weakMfi.fileUrls.count)) * 100.0;
		});
	}];
	[self setCompletionBlock:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakMfi removeObserverWithBlockToken:perToken];
			[NSApp endSheet:pwc.window];
			[pwc.window orderOut:nil];
			if (weakMfi.lastError) { 
				errorHandler(weakMfi);
			}
			[weakMfi.workspace refreshFiles];
		});
	}];
	return pwc;
}

#pragma mark - meat & potatos

-(void)importFile:(NSURL*)fileUrl
{
	NSString *destFileName = fileUrl.lastPathComponent;
	RCFile *existingFile = [self.workspace fileWithName:fileUrl.lastPathComponent];
	BOOL replaceThisFile = NO;
	if (existingFile) {
		if (self.replaceExisting) {
			replaceThisFile = YES;
		} else {
			destFileName = [MultiFileImporter uniqueFileName:destFileName existingFiles:self.workspace.files];
		}
	}
	self.currentFileName = destFileName;
	//synchronously upload the file using the name destfileName
	NSError *err=nil;
	if (replaceThisFile) {
		if (![[Rc2Server sharedInstance] updateFile:existingFile withContents:fileUrl workspace:self.workspace error:&err])
			self.lastError = err;
	} else {
		[[Rc2Server sharedInstance] importFile:fileUrl name:destFileName workspace:self.workspace error:&err];
		if (err)
			self.lastError = err;
	}
	[NSThread sleepForTimeInterval:0.3];
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
	if (nil == self.lastError && [self.filesRemaining count] > 0) {
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
	else {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self importNextFile];
		});
	}
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

@end
