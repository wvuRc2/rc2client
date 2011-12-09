#import "RCMessage.h"

@implementation RCMessage

//parses an array of dictionaries sent from the server and updates stored messages
+(void)syncFromJsonArray:(NSArray*)inArray
{
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	NSMutableSet *unTouched = [[moc fetchObjectsForEntityName:@"RCMessage" withPredicate:nil] mutableCopy];
	for (NSDictionary *dict in inArray) {
		RCMessage *msg = [[moc fetchObjectsForEntityName:@"RCMessage" withPredicate:@"rcptmsgId = %@",
						 [dict objectForKey:@"rcptmsgId"]] anyObject];
		if (nil == msg) {
			msg = [RCMessage insertInManagedObjectContext:moc];
			[msg takeValuesFromDictionary:dict];
		} else { //if ([msg.version integerValue] != [[dict objectForKey:@"version"] integerValue]) {
			[msg takeValuesFromDictionary:dict];
		}
		[unTouched removeObject:msg];
	}
	//any messages in unTouched have been deleted
	for (RCMessage *oldMsg in unTouched)
		[moc deleteObject:oldMsg];
	[moc save:nil];
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

-(void)takeValuesFromDictionary:(NSDictionary*)dict
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
	NSString *ds = [dict objectForKey:@"dateSentStr"];
	self.dateSent = [self marksCheapAssDateParserCauseCocoaSux:ds];
	self.subject = [dict objectForKey:@"subject"];
	self.body = [dict objectForKey:@"body"];
	self.version = [dict objectForKey:@"version"];
	self.rcptmsgId = [dict objectForKey:@"rcptmsgId"];
}

@end
