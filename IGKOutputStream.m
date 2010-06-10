//
//  IGKOutputStream.m
//  Ingredients
//
//  Created by Alex Gordon on 09/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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
