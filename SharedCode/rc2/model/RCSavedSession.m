#import "RCSavedSession.h"

@implementation RCSavedSession

-(NSArray*)commandHistory
{
	NSData *data = self.cmdHistoryData;
	if (data.length < 10)
		return nil;
	return [NSPropertyListSerialization propertyListWithData:data
													 options:NSPropertyListImmutable 
													  format:nil 
													   error:nil];
}

-(void)setCommandHistory:(NSArray *)history
{
	NSError *err=nil;
	self.cmdHistoryData = [NSPropertyListSerialization dataWithPropertyList:history format:NSPropertyListBinaryFormat_v1_0 
																	 options:0 error:&err];
	if (err)
		NSLog(@"got error saving converting cmd history to plist: %@", err);
}
@end
