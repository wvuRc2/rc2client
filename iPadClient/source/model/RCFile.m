//
//  RCFile.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "RCFile.h"

@interface RCFile()
@end

@implementation RCFile

//parses an array of dictionaries sent from the server
+(NSArray*)filesFromJsonArray:(NSArray*)inArray
{
	NSManagedObjectContext *moc = [[UIApplication sharedApplication] valueForKeyPath:@"delegate.managedObjectContext"];
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
	NSDate *lm = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"timestamp"] integerValue]];
	//flush contents if file has been updated
	//FIXME: what is the proper handling here?
	self.lastModified = lm;
	if ([lm timeIntervalSince1970] > [self.localLastModified timeIntervalSince1970]) {
		self.fileContents=nil;
		self.lastModified = lm;
		//FIXME: we are dumping uer's local edits. we should probably ask them something
		self.localEdits=nil;
	}
	if ([self.fileId integerValue] < 1)
		self.fileId = [dict objectForKey:@"id"];
}

-(void)discardEdits
{
	self.localEdits=nil;
	self.localLastModified=nil;
}

#pragma mark - core data overrides

-(void)awakeFromInsert
{
	if (nil == self.lastModified)
		self.lastModified = [NSDate date];
	if (nil == self.sizeString)
		self.sizeString = @"0 bytes";
	if (nil == self.name)
		self.name = @"untitled.R";
}

-(void)willSave
{
	[super willSave];
	if ([self.fileContents isEqualToString:self.localEdits])
		self.localEdits=nil;
}

-(void)setLocalEdits:(NSString *)edits
{
	[self willChangeValueForKey:@"localEdits"];
	[self setPrimitiveLocalEdits:edits];
	[self didChangeValueForKey:@"localEdits"];
	if ([edits length] > 0)
		self.localLastModified = [NSDate date];
	else
		self.localLastModified = nil;
}

#pragma mark - accessors

-(BOOL)contentsLoaded
{
	return nil != self.fileContents;
}

-(NSString*)currentContents
{
	if (nil == self.fileContents && nil == self.localEdits)
		return @"";
	if ([self.localEdits length] > 0)
		return self.localEdits;
	return self.fileContents;
}

-(BOOL)existsOnServer
{
	return [self.fileId integerValue] > 0;
}

@end
