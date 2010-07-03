//
//  IGKOutputStream.m
//  Ingredients
//
//  Created by Alex Gordon on 09/06/2010.
//  Written in 2010 by Fileability.
//

#import "IGKOutputStream.h"


@implementation IGKOutputStream

- (void)appendString:(NSString *)str
{
	const char *utf8data = [str UTF8String];
	[self write:utf8data maxLength:strlen(utf8data)];
}

- (NSString *)stringValue
{
	return [self propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}

@end
