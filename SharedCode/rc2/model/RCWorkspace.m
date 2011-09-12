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
#import <Vyana/NSObject+BlockObservation.h>

@interface RCWorkspace()
@property (nonatomic, copy, readwrite) NSArray *files;
@property (assign) BOOL fetchingFiles;
@end

@implementation RCWorkspace
@synthesize files=_files;
@synthesize fetchingFiles;

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super initWithDictionary:dict])) {
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
		if (success && [results isKindOfClass:[NSArray class]])
			self.files = [RCFile filesFromJsonArray:results];
		self.fetchingFiles=NO;
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
