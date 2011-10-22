//
//  RCWorkspace.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "RCWorkspace.h"
#import "Rc2Server.h"
#import "RCFile.h"
#import "RCWorkspaceShare.h"

NSString * const RCWorkspaceFilesFetchedNotification = @"RCWorkspaceFilesFetchedNotification";

@interface RCWorkspace()
@property (nonatomic, copy, readwrite) NSArray *files;
@property (nonatomic, readwrite) BOOL sharedByOther;
@property (assign) BOOL fetchingFiles;
@property (assign) BOOL fetchingShares;
@end

@implementation RCWorkspace
@synthesize files=_files;
@synthesize fetchingFiles;
@synthesize fetchingShares;
@synthesize shares;
@synthesize sharedByOther;

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super initWithDictionary:dict])) {
		self.shares = [NSMutableArray array];
		self.sharedByOther = [[dict objectForKey:@"shared"] boolValue];
	}
	return self;
}

- (void)dealloc
{
	self.files=nil;
	[self removeAllBlockObservers];
	[super dealloc];
}

-(void)refreshFiles
{
	self.fetchingFiles=YES;
	[[Rc2Server sharedInstance] fetchFileList:self completionHandler:^(BOOL success, id results) {
		if (success && [results isKindOfClass:[NSArray class]]) {
			self.files = [RCFile filesFromJsonArray:results];
			[[NSNotificationCenter defaultCenter] postNotificationName:RCWorkspaceFilesFetchedNotification object:self];
		}
		self.fetchingFiles=NO;
	}];
}

-(void)refreshShares
{
	self.fetchingShares=YES;
	[[Rc2Server sharedInstance] fetchWorkspaceShares:self completionHandler:^(BOOL success, id results) {
		self.fetchingShares=NO;
		[self willChangeValueForKey:@"shares"];
		[self didChangeValueForKey:@"shares"];
	}];
}

-(NSArray*)files
{
	if (nil == _files && !self.fetchingFiles)
		[self refreshFiles];
	return _files;
}

-(void)setFiles:(NSArray*)anArray
{
	if ([anArray isEqual:_files])
		return;
	[_files release];
	_files = [anArray copy];
}

-(RCFile*)fileWithId:(NSNumber*)fileId
{
	for (RCFile *aFile in self.files) {
		if ([fileId isEqualToNumber:aFile.fileId])
			return aFile;
	}
	return nil;
}

-(void)addFile:(RCFile *)aFile
{
	if ([_files containsObject:aFile])
		return;
	if (nil == _files)
		self.files = [NSArray arrayWithObject:aFile];
	else
		self.files = [_files arrayByAddingObject:aFile];
}

@end
