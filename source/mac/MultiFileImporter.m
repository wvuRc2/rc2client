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
@end

@implementation MultiFileImporter

+(NSDragOperation)validateTableViewFileDrop:(id <NSDraggingInfo>)info
{
	static NSDictionary *readOptions=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		readOptions = [[NSDictionary alloc] initWithObjectsAndKeys:@YES, NSPasteboardURLReadingFileURLsOnlyKey,
					   ARRAY((id)kUTTypePlainText,(id)kUTTypePDF), NSPasteboardURLReadingContentsConformToTypesKey,
					   nil];
	});
	//don't allow local drags
	if (nil != [info draggingSource])
		return NSDragOperationNone;
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
	NSMutableArray *existingNames = [NSMutableArray array]; //[existingFiles valueForKey:@"name"];
	for (id obj in existingFiles) {
		if ([obj isKindOfClass:[RCFile class]])
			[existingNames addObject:obj];
	}
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
		[alert am_beginSheetModalForWindow:tableView.window completionHandler:^(NSAlert *theAlert, NSInteger btxIdx) {
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
	[[Rc2Server sharedInstance] importFiles:self.fileUrls toContainer:self.container completionHandler:^(BOOL success, id results) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self markAsComplete];
			[NSApp endSheet:pwc.window];
			[pwc.window orderOut:nil];
			if (success) {
				if ([self.container isKindOfClass:[RCWorkspace class]])
					[(RCWorkspace*)self.container refreshFiles];
			} else {
				[NSAlert displayAlertWithTitle:@"Error Importing Files" details:results];
			}
		});
	} progress:^(CGFloat per) {
		pwc.percentComplete = round(per * 100);
	}];
	return pwc;
}

#pragma mark - meat & potatos


-(void)markAsComplete
{
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	self.myState = kState_Done;
	[self didChangeValueForKey:@"isFinished"];
	[self didChangeValueForKey:@"isExecuting"];
}

@end
