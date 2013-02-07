#import "_RCMessage.h"

@interface RCMessage : _RCMessage
+(void)syncFromJsonArray:(NSArray*)inArray;
-(void)updateValuesFromDictionary:(NSDictionary*)dict;
@end
