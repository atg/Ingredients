//
//  NSString+Utilities.m
//  Chocolat
//
//  Created by Alex Gordon on 13/07/2009.
//  Copyright 2009 Fileability. All rights reserved.
//

#import "NSString+Utilities.h"


@implementation NSString (Utilities)



- (BOOL)startsWith:(NSString *)s
{
	if ([self length] >= [s length] && [[self substringToIndex:[s length]] isEqualToString:s])
		return YES;
	return NO;
}


+ (NSString *)stringByGeneratingUUID
{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	NSString *uuidString = (NSString *)NSMakeCollectable((CFUUIDCreateString(NULL, uuidRef)));
	CFRelease(uuidRef);
	return uuidString;
}
+ (NSString *)stringByGeneratingXcodeHexadecimalUUID
{
	//24 Uppercase Hexadecimal Characters
	//For example: 758912EA10C2ABB500F9A5CF
	
	NSMutableString *uuidString = [[NSMutableString alloc] initWithCapacity:24];
	
	//We create 6 groups of 4 characters
	int i;
	for (i = 0; i < 6; i++)
	{
		long r = random();
		r %= 65536; // 16^4
		[uuidString appendString:[[NSString stringWithFormat:@"%04x", r] uppercaseString]];
	}
	
	return uuidString;
}



@end
