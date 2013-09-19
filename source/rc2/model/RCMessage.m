#import "RCMessage.h"

@implementation RCMessage

//parses an array of dictionaries sent from the server and updates stored messages
+(void)syncFromJsonArray:(NSArray*)inArray
{
	NSMutableSet *unTouched = [NSMutableSet setWithArray:[RCMessage MR_findAll]];
	for (NSDictionary *dict in inArray) {
		RCMessage *msg = [RCMessage MR_findFirstByAttribute:@"rcptmsgId" withValue:[dict objectForKey:@"rcptmsgId"]];
		if (nil == msg) {
			msg = [RCMessage MR_createEntity];
			[msg updateValuesFromDictionary:dict];
		} else { //if ([msg.version integerValue] != [[dict objectForKey:@"version"] integerValue]) {
			[msg updateValuesFromDictionary:dict];
		}
		[unTouched removeObject:msg];
	}
	//any messages in unTouched have been deleted
	for (RCMessage *oldMsg in unTouched)
		[oldMsg MR_deleteEntity];
}

-(NSDate*)marksCheapAssDateParserCauseCocoaSux:(NSString*)str
{
	NSDateComponents *dc = [[NSDateComponents alloc] init];
	[dc setYear:[[str substringWithRange:NSMakeRange(0, 4)] intValue]];
	[dc setMonth:[[str substringWithRange:NSMakeRange(5, 2)] intValue]];
	[dc setDay:[[str substringWithRange:NSMakeRange(8, 2)] intValue]];
	[dc setHour:[[str substringWithRange:NSMakeRange(11, 2)] intValue]];
	[dc setMinute:[[str substringWithRange:NSMakeRange(14, 2)] intValue]];
	[dc setSecond:[[str substringWithRange:NSMakeRange(17, 2)] intValue]];
	
	return [[NSCalendar currentCalendar] dateFromComponents:dc];
}

-(void)updateValuesFromDictionary:(NSDictionary*)dict
{
//	NSDateFormatter *form = [[[NSDateFormatter alloc] init] autorelease];
//	[form setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
//	[form setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	self.messageId = [dict objectForKey:@"messageId"];
	NSString *dr = [dict objectForKey:@"dateReadStr"];
	if ([dr length] == 19)
		self.dateRead = [self marksCheapAssDateParserCauseCocoaSux:dr];
	self.sender = [dict objectForKey:@"sender"];
	self.priority = [dict objectForKey:@"priority"];
	self.dateSent = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"dateSent"] doubleValue] / 1000.0];
	self.subject = [dict objectForKey:@"subject"];
	self.body = [dict objectForKey:@"body"];
	self.version = [dict objectForKey:@"version"];
	self.rcptmsgId = [dict objectForKey:@"id"];
}

@end
