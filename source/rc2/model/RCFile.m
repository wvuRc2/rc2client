//
//  RCFile.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "RCFile.h"
#import "Rc2Server.h"
#import "Rc2FileType.h"

@interface RCFile()
@property (nonatomic, copy) NSString *cachedContent;
@property (nonatomic, readwrite) Rc2FileType *fileType;
@property (nonatomic, readwrite) BOOL locallyModified;
@property (nonatomic, strong) NSMutableDictionary *attrCache;
@property (nonatomic, weak, readwrite) id<RCFileContainer> container;
@end

@implementation RCFile

//parses an array of dictionaries sent from the server
+(NSArray*)filesFromJsonArray:(NSArray*)inArray container:(id<RCFileContainer>)container
{
	if (nil == inArray || [[NSNull null] isEqual:inArray])
		return [NSArray array];
	NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[inArray count]];
	for (NSDictionary *dict in inArray) {
		RCFile *file = [RCFile MR_findFirstByAttribute:@"fileId" withValue:[dict objectForKey:@"id"]];
		if (nil == file) {
			file = [RCFile MR_createEntity];
		}
		file.container = container;
		[file updateWithDictionary:dict];
		[outArray addObject:file];
	}
	return outArray;
}

-(void)updateWithDictionary:(NSDictionary*)dict
{
	self.name = [dict objectForKey:@"name"];
	self.sizeString = [dict objectForKey:@"friendlySize"];
	self.versionValue = [[dict objectForKey:@"version"] intValue];
	self.fileSize = [dict objectForKey:@"filesize"];

	//fire off fetching the contets if we don't have them
	//TODO: this should check the version field and any cached value
//	if ([[dict objectForKey:@"fsize"] cgFloatValue] < 4096)
//		[RC2_SharedInstance() fetchFileContents:file completionHandler:^(BOOL success, id obj) {}];

	NSNumber *aDate = [dict objectForKey:@"startDate"];
	self.startDate = aDate ? [NSDate dateWithTimeIntervalSince1970:[aDate longLongValue]/1000] : nil;
	aDate = [dict objectForKey:@"endDate"];
	self.endDate = aDate ? [NSDate dateWithTimeIntervalSince1970:[aDate longLongValue]/1000] : nil;

	NSDate *lm = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"lastmodified"] longLongValue]/1000];
	//flush contents if file has been updated
	if (!self.savingToServer && lm.timeIntervalSinceReferenceDate > self.lastModified.timeIntervalSinceReferenceDate) {
		[[NSFileManager defaultManager] removeItemAtPath:self.fileContentsPath error:nil];
		self.cachedContent=nil;
		//FIXME: we are dumping uer's local edits. we should probably ask them something
		self.localEdits=nil;
	}
	self.lastModified = lm;
	if (!self.isInserted && [lm timeIntervalSince1970] > [self.localLastModified timeIntervalSince1970]) {
		//this case should likely never happen
		self.cachedContent=nil;
		self.lastModified = lm;
		self.localEdits=nil;
	}
	if (!self.isTextFile)
		[self discardEdits];
	if ([self.fileId integerValue] < 1)
		self.fileId = [dict objectForKey:@"id"];
}

-(void)updateContentsFromServer:(BasicBlock1IntArg)hblock
{
	if (self.isTextFile) {
		[RC2_SharedInstance() fetchFileContents:self completionHandler:^(BOOL success, id results) {
			if (success) {
				NSError *err=nil;
				NSURL *fileUrl = [NSURL fileURLWithPath:self.fileContentsPath];
				NSNumber *fsize;
				if (![fileUrl getResourceValue:&fsize forKey:NSURLFileSizeKey error:&err]) {
					Rc2LogWarn(@"failed to get file size for %@:%@", self.name, err);
				}
				self.fileSize = fsize;
				AMFileSizeTransformer *trans = [[AMFileSizeTransformer alloc] init];
				self.sizeString = [trans transformedValue:fsize];
				NSFileManager *fm = [[NSFileManager alloc] init];
				[fm setAttributes:@{NSFileCreationDate:self.lastModified, NSFileModificationDate:self.lastModified} ofItemAtPath:self.fileContentsPath error:&err];
				if (err)
					Rc2LogWarn(@"got error setting file attrs:%@", err);
				hblock(YES);
			} else {
				Rc2LogError(@"error fetching content for file %@", self.fileId);
				hblock(NO);
			}
		}];
	} else {
		//binary file: just delete cached copy and refetch
		[[NSFileManager defaultManager] removeItemAtPath:self.fileContentsPath error:nil];
		[RC2_SharedInstance() fetchFileContents:self completionHandler:^(BOOL success, id obj) {
			hblock(success);
		}];
	}
}

-(void)discardEdits
{
	self.localEdits=nil;
	self.localLastModified=nil;
	self.cachedContent=nil;
}

#pragma mark - core data overrides

-(void)awakeFromInsert
{
	[super awakeFromInsert];
	self.fileType = [Rc2FileType fileTypeWithExtension:self.name.pathExtension];
	if (nil == self.lastModified)
		self.lastModified = [NSDate date];
	if (nil == self.sizeString)
		self.sizeString = @"0 bytes";
	if (nil == self.name)
		self.name = @"untitled.R";
	if (nil == self.readOnly)
		self.readOnly = @NO;
}

-(void)awakeFromFetch
{
	[super awakeFromFetch];
	self.fileType = [Rc2FileType fileTypeWithExtension:self.name.pathExtension];
	if (nil == self.readOnly)
		self.readOnly = @NO;
	if (!self.isTextFile)
		self.localEdits=nil;
	self.locallyModified = self.localEdits.length > 0;
}

-(void)willSave
{
	[super willSave];
	if ([self.cachedContent isEqualToString:self.localEdits])
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
	//FIXME: this is overblown
	if (self.cachedContent && nil == self.localEdits)
		[self.cachedContent writeToFile:self.fileContentsPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void)setLocalEdits:(NSString *)edits
{
	if (!self.isTextFile)
		return;
	if (self.cachedContent && [edits isEqualToString:self.cachedContent])
		edits = nil;
	[self willChangeValueForKey:@"localEdits"];
	[self setPrimitiveLocalEdits:[edits copy]];
	[self didChangeValueForKey:@"localEdits"];
	if ([edits length] > 0)
		self.localLastModified = [NSDate date];
	else
		self.localLastModified = nil;
	self.locallyModified = self.localEdits.length > 0;
}

-(NSString*)mimeType
{
	return self.fileType.mimeType;
}

#pragma mark - accessors

-(void)setName:(NSString *)name
{
	[self willChangeValueForKey:@"name"];
	[self setPrimitiveName:name];
	[self didChangeValueForKey:@"name"];
	self.fileType = [Rc2FileType fileTypeWithExtension:self.name.pathExtension];
}

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
		Rc2LogError(@"got error saving local attrs: %@", err);
}

-(BOOL)isTextFile
{
	if ([self isFault])
		[self name];
	return self.fileType.isTextFile;
}

-(BOOL)contentsLoaded
{
	if (self.isTextFile && self.cachedContent)
		return YES;
	return [[NSFileManager defaultManager] fileExistsAtPath:self.fileContentsPath];
}

-(NSString*)currentContents
{
//	if (nil == self.fileContents && nil == self.localEdits)
//		return @"";
	if (!self.isTextFile)
		return nil;
	if ([self.localEdits length] > 0)
		return self.localEdits;
	if (!self.existsOnServer && nil == self.cachedContent)
		self.cachedContent = @"\n";
	if (nil == self.cachedContent) {
		//we need to load our file contents. first, see if they exist on the file system
		NSString *cacheContents = [NSString stringWithContentsOfFile:self.fileContentsPath encoding:NSUTF8StringEncoding error:nil];
		if (nil == cacheContents) {
			//load synchronously from server
			cacheContents = [RC2_SharedInstance() fetchFileContentsSynchronously:self];
			if (cacheContents)
				[cacheContents writeToFile:self.fileContentsPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		}
		//only cache if less than 10K
		if (cacheContents.length < 10240)
			self.cachedContent = cacheContents;
		return cacheContents;
	}
	return self.cachedContent;
}

-(BOOL)existsOnServer
{
	return [self.fileId integerValue] > 0;
}

-(id)fileIcon
{
	return self.fileType.fileImage;
}

-(id)permissionImage
{
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
//	if ([self.kind isEqualToString:@"done"]) return [NSImage imageNamed:@"turnedin"];
//	if ([self.kind isEqualToString:@"graded"]) return [NSImage imageNamed:@"graded"];
	if ([self readOnlyValue]) return [NSImage imageNamed:NSImageNameLockLockedTemplate];
#else
//	if ([self.kind isEqualToString:@"done"]) return [UIImage imageNamed:@"turnedin"];
//	if ([self.kind isEqualToString:@"graded"]) return [UIImage imageNamed:@"graded"];
	if ([self readOnlyValue]) return [UIImage imageNamed:@"lock"];
#endif
	return nil;
}

-(NSString*)fileContentsPath
{
	return [[self.container fileCachePath] stringByAppendingPathComponent:self.name];
}

-(id)debugQuickLookObject
{
	return [NSString stringWithFormat:@"RCFile: %@(%@)", self.name, self.fileId];
}

@synthesize fileType;
@synthesize fileSize;
@synthesize attrCache;
@synthesize locallyModified;
@synthesize container;
@synthesize cachedContent;
@synthesize savingToServer;
@end
