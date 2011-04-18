#import <Cocoa/Cocoa.h>

@interface NSImage (CTAdditions)
+(NSImage*)imageWithPath:(NSString *)path;
+(NSImage*)imageInAppOrCTFrameworkNamed:(NSString*)name;
+(NSImage*)imageInFrameworkNamed:(NSString*)name;
@end
