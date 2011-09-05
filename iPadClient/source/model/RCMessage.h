#import "_RCMessage.h"

@interface RCMessage : _RCMessage
+(void)syncFromJsonArray:(NSArray*)inArray;
-(void)takeValuesFromDictionary:(NSDictionary*)dict;
@end
