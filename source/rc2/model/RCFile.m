//
//  RCFile.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "RCFile.h"
#import "Rc2Server.h"

@interface RCFile()
@property (nonatomic, readwrite) BOOL locallyModified;
@property (nonatomic, strong) NSMutableDictionary *attrCache;
@end

@implementation RCFile

//parses an array of dictionaries sent from the server
+(NSArray*)filesFromJsonArray:(NSArray*)inArray
{
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[inArray count]];
	for (NSDictionary *dict in inArray) {
		RCFile *file = [[moc fetchObjectsForEntityName:@"RCFile" withPredicate:@"fileId = %@",
						[dict objectForKey:@"id"]] anyObject];
		if (nil == file) {
			file = [RCFile insertInManagedObjectContext:moc];
		}
		[file updateWithDictionary:dict];
		[outArray addObject:file];
	}
	return outArray;
}

-(void)updateWithDictionary:(NSDictionary*)dict
{
	self.name = [dict objectForKey:@"name"];
	self.sizeString = [dict objectForKey:@"size"];
	if ([[dict objectForKey:@"kind"] isKindOfClass:[NSString class]])
		self.kind = [dict objectForKey:@"kind"];
	self.readOnlyValue = [[dict objectForKey:@"readonly"] boolValue];
	NSDate *lm = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"timestamp"] integerValue]];
	//flush contents if file has been updated
	if (lm.timeIntervalSinceNow > self.lastModified.timeIntervalSinceNow) {
		[[NSFileManager defaultManager] removeItemAtPath:self.fileContentsPath error:nil];
		self.fileContents=nil;
		//FIXME: we are dumping uer's local edits. we should probably ask them something
		self.localEdits=nil;
	}
	self.lastModified = lm;
	if (!self.isInserted && [lm timeIntervalSince1970] > [self.localLastModified timeIntervalSince1970]) {
		self.fileContents=nil;
		self.lastModified = lm;
		//FIXME: we are dumping uer's local edits. we should probably ask them something
		self.localEdits=nil;
	}
	if (!self.isTextFile)
		[self discardEdits];
	if ([self.fileId integerValue] < 1)
		self.fileId = [dict objectForKey:@"id"];
}

-(void)updateContentsFromServer
{
	if (self.isTextFile) {
		if (nil == self.fileContents) {
			[[Rc2Server sharedInstance] fetchFileContents:self completionHandler:^(BOOL success, id results) {
				if (success) {
					self.fileContents = results;
					[results writeToFile:self.fileContentsPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
				} else
					NSLog(@"error fetching content");
			}];
		}
	} else {
		//just delete cached copy and refetch for binary files
		[[NSFileManager defaultManager] removeItemAtPath:self.fileContentsPath error:nil];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[[Rc2Server sharedInstance] fetchBinaryFileContentsSynchronously:self];
		});
	}
}

-(void)discardEdits
{
	self.localEdits=nil;
	self.localLastModified=nil;
}

#pragma mark - core data overrides

-(void)awakeFromInsert
{
	[super awakeFromInsert];
	if (nil == self.lastModified)
		self.lastModified = [NSDate date];
	if (nil == self.sizeString)
		self.sizeString = @"0 bytes";
	if (nil == self.name)
		self.name = @"untitled.R";
	if (nil == self.readOnly)
		self.readOnly = [NSNumber numberWithBool:NO];
}

-(void)awakeFromFetch
{
	[super awakeFromFetch];
	if (nil == self.readOnly)
		self.readOnly = [NSNumber numberWithBool:NO];
	if (!self.isTextFile)
		self.localEdits=nil;
	self.locallyModified = self.localEdits.length > 0;
}

-(void)willSave
{
	[super willSave];
	if ([self.fileContents isEqualToString:self.localEdits])
		self.localEdits=nil;
}

-(void)prepareForDeletion
{
	[super prepareForDeletion];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *cachePath = self.fileContentsPath;
	if ([fm fileExistsAtPath:cachePath])
		[fm removeItemAtPath:cachePath error:nil];
}

-(void)didSave
{
	[super didSave];
	self.locallyModified = self.localEdits.length > 0;
	if (self.fileContents)
		[self.fileContents writeToFile:self.fileContentsPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void)setLocalEdits:(NSString *)edits
{
	if (!self.isTextFile)
		return;
	if ([edits isEqualToString:self.fileContents])
		edits = nil;
	if (edits && edits.length < 1)
		NSLog(@"why are we saving local edits of length < 1?");
	[self willChangeValueForKey:@"localEdits"];
	[self setPrimitiveLocalEdits:[edits copy]];
	[self didChangeValueForKey:@"localEdits"];
	if ([edits length] > 0)
		self.localLastModified = [NSDate date];
	else
		self.localLastModified = nil;
	self.locallyModified = self.localEdits.length > 0;
}

-(void)setFileContents:(NSString *)ftext
{
	if (!self.isTextFile)
		return;
	[self willChangeValueForKey:@"fileContents"];
	[self setPrimitiveFileContents:[ftext copy]];
	[self didChangeValueForKey:@"fileContents"];
	self.localEdits = ftext; //will clear them if the same
	self.locallyModified = self.localEdits.length > 0;
}

#pragma mark - accessors

-(NSMutableDictionary*)localAttrs
{
	if (nil == self.attrCache) {
		NSData *data = self.localAttributes;
		if (data) {
			//read from plist
			self.attrCache = [NSPropertyListSerialization propertyListWithData:data
																	   options:NSPropertyListMutableContainers 
																		format:nil 
																		 error:nil];
		}
		if (nil == self.attrCache)
			self.attrCache = [NSMutableDictionary dictionary];
	}
	return self.attrCache;
}

-(void)setLocalAttrs:(NSMutableDictionary *)attrs
{
	self.attrCache = [attrs mutableCopy];
	NSError *err=nil;
	self.localAttributes = [NSPropertyListSerialization dataWithPropertyList:attrs format:NSPropertyListXMLFormat_v1_0 
																	 options:0 error:&err];
	if (err)
		NSLog(@"got error saving local attrs: %@", err);
}

-(BOOL)isTextFile
{
	NSString *ext = self.name.pathExtension;
	if ([[Rc2Server acceptableTextFileSuffixes] containsObject:ext])
		return YES;
	return NO;
}

-(BOOL)contentsLoaded
{
	if (self.isTextFile)
		return nil != self.fileContents;
	return [[NSFileManager defaultManager] fileExistsAtPath:self.fileContentsPath];
}

-(NSString*)currentContents
{
//	if (nil == self.fileContents && nil == self.localEdits)
//		return @"";
	if ([self.localEdits length] > 0)
		return self.localEdits;
	if (nil == self.fileContents) {
		//we need to load our file contents. first, see if they exist on the file system
		NSString *cacheContents = [NSString stringWithContentsOfFile:self.fileContentsPath encoding:NSUTF8StringEncoding error:nil];
		if (nil == cacheContents) {
			//load synchronously from server
			cacheContents = [[Rc2Server sharedInstance] fetchFileContentsSynchronously:self];
		}
		self.fileContents = cacheContents;
		return cacheContents;
	}
	return self.fileContents;
}

-(BOOL)existsOnServer
{
	return [self.fileId integerValue] > 0;
}

-(id)fileIcon
{
	#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
		NSString *ext = [self.name pathExtension];
		if ([ext isEqualToString:@"R"])
			return [NSImage imageNamed:@"Rdoc"];
		else if ([ext isEqualToString:@"RnW"])
			return [NSImage imageNamed:@"RnW"];
		NSImage *img = [[NSWorkspace sharedWorkspace] iconForFileType:ext];
		[img setSize:NSMakeSize(48, 48)];
		return img;
	#else
		NSString *imgName = @"doc";
		if ([self.name hasSuffix:@".R"])
			imgName = @"RDoc";
		else if ([self.name hasSuffix:@".RnW"])
			imgName = @"RnWDoc";
		return [UIImage imageNamed:imgName];
	#endif
}

-(id)permissionImage
{
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
	if ([self.kind isEqualToString:@"done"]) return [NSImage imageNamed:@"turnedin"];
	if ([self.kind isEqualToString:@"graded"]) return [NSImage imageNamed:@"graded"];
	if ([self readOnlyValue]) return [NSImage imageNamed:NSImageNameLockLockedTemplate];
#else
	if ([self.kind isEqualToString:@"done"]) return [UIImage imageNamed:@"turnedin"];
	if ([self.kind isEqualToString:@"graded"]) return [UIImage imageNamed:@"graded"];
	if ([self readOnlyValue]) return [UIImage imageNamed:@"lock"];
#endif
	return nil;
}

-(NSString*)fileContentsPath
{
	NSString *filePath = [[NSString stringWithFormat:@"files/%@", self.fileId] stringByAppendingPathExtension:self.name.pathExtension];
	NSString *fullPath = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:filePath];
	ZAssert([[NSFileManager defaultManager] fileExistsAtPath:[fullPath stringByDeletingLastPathComponent]], 
		@"file cache directory doesn't exist");
	return fullPath;
}

@synthesize attrCache;
@synthesize locallyModified;
@end
