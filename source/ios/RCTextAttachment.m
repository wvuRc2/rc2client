//
//  RCTextAttachment.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/28/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCTextAttachment.h"

@implementation RCTextAttachment : NSTextAttachment
@end

@implementation RCFileAttachment

-(id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self.fileId = [aDecoder decodeObjectForKey:@"RCFILEID"];
		self.fileName = [aDecoder decodeObjectForKey:@"RCFILENAME"];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:self.fileId forKey:@"RCFILEID"];
	[aCoder encodeObject:self.fileName forKey:@"RCFILENAME"];
}

@end

@implementation RCImageAttachment

-(id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self.imageId = [aDecoder decodeObjectForKey:@"RCIMGID"];
		self.imageUrl = [aDecoder decodeObjectForKey:@"RCIMGURL"];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:self.imageId forKey:@"RCIMGID"];
	[aCoder encodeObject:self.imageUrl forKey:@"RCIMGURL"];
}

-(CGRect)bounds
{
	return CGRectMake(0, 0, 64, 64);
}

@end
