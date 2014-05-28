//
//  RCProject.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCProject.h"
#import "RCWorkspace.h"
#import "Rc2Server.h"
#import "RCFile.h"

//declared in RCFileContainer.h
NSString * const RCFileContainerChangedNotification = @"RCFileContainerChangedNotification";

@interface RCProject ()
@property (nonatomic, strong, readwrite) NSArray *workspaces;
@property (nonatomic, copy, readwrite) NSArray *files;
@property (nonatomic, copy) NSString *fspath;
@end

@implementation RCProject

+(NSArray*)projectSortDescriptors
{
	static NSArray *sds=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sds = @[[NSSortDescriptor sortDescriptorWithKey:@"isAdmin" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"isClass" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
	});
	return sds;
}

+(NSArray*)projectsForJsonArray:(NSArray*)jsonArray includeAdmin:(BOOL)admin
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:jsonArray.count + 1];
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
	if (admin)
		[a addObject:[[RCProject alloc] initWithDictionary:@{@"name":@"Admin",@"id":@-2,@"type":@"admin"}]];
#endif
	for (NSDictionary *d in jsonArray)
		[a addObject:[[RCProject alloc] initWithDictionary:d]];
	[a sortUsingDescriptors:[RCProject projectSortDescriptors]];
	return a;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.projectId = [dict objectForKey:@"id"];
		[self updateWithDictionary:dict];
		//this needs to run after init has returned so we'll have had our project set
		dispatch_async(dispatch_get_main_queue(), ^{
			self.files = [RCFile filesFromJsonArray:[dict objectForKey:@"files"] container:self];
		});
	}
	return self;
}

-(void)updateWithDictionary:(NSDictionary*)dict
{
	self.name = [dict objectForKey:@"name"];
	if ([[dict objectForKey:@"type"] isKindOfClass:[NSString class]])
		self.type = [dict objectForKey:@"type"];
	NSArray *wspaces = [dict objectForKey:@"workspaces"];
	if (wspaces.count > 0) {
		NSMutableArray *a = [NSMutableArray arrayWithCapacity:wspaces.count];
		for (NSDictionary *d in wspaces) {
			RCWorkspace *wspace = [[RCWorkspace alloc] initWithDictionary:d];
			wspace.project = self;
			if (wspace)
				[a addObject:wspace];
		}
		[a sortUsingSelector:@selector(compareWithItem:)];
		self.workspaces = [a copy];
	}
}

-(void)addFile:(RCFile *)aFile
{
	if ([_files containsObject:aFile])
		return;
	if (nil == _files)
		self.files = [NSArray arrayWithObject:aFile];
	else
		self.files = [_files arrayByAddingObject:aFile];
	[aFile setValue:self forKey:@"container"];
	ZAssert(aFile.container == self, @"not set as container");
	[[NSNotificationCenter defaultCenter] postNotificationName:RCFileContainerChangedNotification object:self];
}

-(void)removeFile:(RCFile*)aFile
{
	[aFile MR_deleteEntity];
	NSInteger idx = [_files indexOfObject:aFile];
	if (idx != NSNotFound)
		self.files = [_files arrayByRemovingObjectAtIndex:idx];
}

-(RCFile*)fileWithId:(NSNumber*)fileId
{
	__block RCFile *theFile;
	[self.files enumerateObjectsUsingBlock:^(RCFile *aFile, NSUInteger idx, BOOL *stop) {
		if ([aFile.fileId isEqualToNumber:fileId]) {
			theFile = aFile;
			*stop = YES;
		}
	}];
	return theFile;
}

-(void)removeWorkspace:(RCWorkspace*)wspace
{
	NSInteger idx = [_workspaces indexOfObject:wspace];
	if (idx != NSNotFound)
		self.workspaces = [self.workspaces arrayByRemovingObjectAtIndex:idx];
}

-(NSString*)fileCachePath
{
	if (nil == _fspath) {
		NSString *filePath = [NSString stringWithFormat:@"projects/%@", self.projectId];
		self.fspath = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:filePath];
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDir=NO;
		NSError *err=nil;
		BOOL exists = [fm fileExistsAtPath:_fspath isDirectory:&isDir];
		if (exists && !isDir)
			[fm removeItemAtPath:_fspath error:nil];
		if (![fm createDirectoryAtPath:_fspath withIntermediateDirectories:YES attributes:nil error:&err])
			Rc2LogError(@"failed to create project directory:%@", err);
	}
	return _fspath;
}

-(BOOL)userEditable
{
	if ([_type isEqualToString:@"admin"] || [_type isEqualToString:@"class"] || [_type isEqualToString:@"shared"])
		return NO;
	return YES;
}

-(BOOL)isAdmin
{
	return [_type isEqualToString:@"admin"];
}

-(BOOL)isClass
{
	return [_type isEqualToString:@"class"];
}

-(BOOL)isShared
{
	return [_type isEqualToString:@"shared"];
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"RCProject: %@, (%d workspaces)", self.name, (int)_workspaces.count];
}

-(id)debugQuickLookObject
{
	return [NSString stringWithFormat:@"RCProject: %@(%@), %d workspaces", self.name, self.projectId, (int)_workspaces.count];
}

@end
