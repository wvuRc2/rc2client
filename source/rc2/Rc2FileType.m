//
//  Rc2FileType.m
//  Rc2Client
//
//  Created by Mark Lilback on 8/29/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "Rc2FileType.h"

@interface Rc2FileType()
@property (nonatomic, copy) NSDictionary *data;
@end

@implementation Rc2FileType

+(NSArray*)allFileTypes
{
	static NSArray *sAllTypes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RC2FileTypes" ofType:@"plist"]];
		ZAssert(dict, @"failed to load file types dict");
		NSArray *rawTypes = [dict objectForKey:@"FileTypes"];
		NSMutableArray *types = [NSMutableArray arrayWithCapacity:rawTypes.count];
		for (NSDictionary *aDict in rawTypes)
			[types addObject:[[Rc2FileType alloc] initWithDictionary:aDict]];
		sAllTypes = [types copy];
	});
	return sAllTypes;
}

+(Rc2FileType*)fileTypeWithExtension:(NSString*)fileExt
{
	if ([fileExt hasPrefix:@"."])
		fileExt = [fileExt substringFromIndex:1];
	for (Rc2FileType *ft in [Rc2FileType allFileTypes]) {
		if (NSOrderedSame == [ft.extension caseInsensitiveCompare:fileExt])
			return ft;
	}
	return nil;
}

+(NSArray*)imageFileTypes
{
	static NSArray *imageTypes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		imageTypes = [[Rc2FileType allFileTypes] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isImage = YES"]];
	});
	return imageTypes;
}

+(NSArray*)textFileTypes
{
	static NSArray *textTypes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		textTypes = [[Rc2FileType allFileTypes] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isTextFile = YES"]];
	});
	return textTypes;
}

+(NSArray*)importableFileTypes
{
	static NSArray *importTypes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		importTypes = [[Rc2FileType allFileTypes] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isImportable = YES"]];
	});
	return importTypes;
}

+(NSArray*)creatableFileTypes
{
	static NSArray *createTypes;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		createTypes = [[Rc2FileType allFileTypes] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isCreatable = YES"]];
	});
	return createTypes;
}

- (id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.data = dict;
	}
	return self;
}

-(NSString*)name { return [self.data objectForKey:@"Name"]; }
-(NSString*)extension { return [self.data objectForKey:@"Extension"]; }
-(NSString*)details { return [self.data objectForKey:@"Description"]; }
-(NSString*)iconName { return [self.data objectForKey:@"IconName"]; }
-(NSString*)mimeType
{
	NSString *mt = [self.data objectForKey:@"MimeType"];
	if (nil == mt) {
		if (self.isTextFile)
			mt = @"text/plain";
		else
			mt = @"application/octet-stream";
	}
	return mt;
}

-(BOOL)isTextFile { return [[self.data objectForKey:@"IsTextFile"] boolValue]; }
-(BOOL)isImportable  { return [[self.data objectForKey:@"Importable"] boolValue]; }
-(BOOL)isCreatable  { return [[self.data objectForKey:@"Creatable"] boolValue]; }
-(BOOL)isImage  { return [[self.data objectForKey:@"IsImage"] boolValue]; }
-(BOOL)isSourceFile { return [[self.data objectForKey:@"IsSrc"] boolValue]; }
-(BOOL)isSweave { return [[self.data objectForKey:@"IsSweave"] boolValue]; }
-(BOOL)isRMarkdown { return [[self.data objectForKey:@"IsRMarkdown"] boolValue]; }

-(id)image
{
	id img=nil;
	#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
		img = [NSImage imageNamed:[NSString stringWithFormat:@"console/%@-file", self.extension]];
	#else
		img = [UIImage imageNamed:[NSString stringWithFormat:@"console/%@-file", self.extension]];
		if (nil == img)
			img = [UIImage imageNamed:@"console/plain-file"];
	#endif
	return img;
}

-(id)fileImage
{
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
	if (self.iconName) {
		NSImage *img = [NSImage imageNamed:self.iconName];
		if (nil == img)
			img = [[NSWorkspace sharedWorkspace] iconForFileType:self.extension];
		[img setSize:NSMakeSize(48, 48)];
		if (img)
			return img;
	}
#endif
	return self.image;
}

@end


