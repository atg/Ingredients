//
//  NSString+Utilities.m
//  Chocolat
//
//  Created by Alex Gordon on 13/07/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
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

- (BOOL)containsString:(NSString *)s
{
	//BOOL isLike = [self isLike:[NSString stringWithFormat:@"*%@*", s]];
	NSRange r = [self rangeOfString:s];
	//NSLog(@"r = %@", NSStringFromRange(r));
	//NSLog(@"NSNotFound = %lu", NSNotFound);
	//NSLog(@"r.location != NSNotFound = %@", r.location != NSNotFound);
	BOOL contains = r.location != NSNotFound;
	
	/*if (contains != isLike)
	{
		NSLog(@"=== DIFFERENCE ===");
		NSLog(@"\t self = '%@'", self);
		NSLog(@"\t s = '%@'", s);
		NSLog(@"\t contains = %d", contains);
		NSLog(@"\t isLike = %d", isLike);
	}*/
	
	return contains;
}

- (BOOL)caseInsensitiveContainsString:(NSString *)s
{
	NSRange r = [self rangeOfString:s options:NSCaseInsensitiveSearch];
	BOOL contains = r.location != NSNotFound;
	return contains;
}

- (BOOL)caseInsensitiveHasPrefix:(NSString *)s
{
	return [[self lowercaseString] hasPrefix:[s lowercaseString]];
}

- (BOOL)caseInsensitiveHasSuffix:(NSString *)s
{
	return [[self lowercaseString] hasSuffix:[s lowercaseString]];
}

- (BOOL)isCaseInsensitiveEqual:(NSString *)s
{
	return [self compare:s options:NSCaseInsensitiveSearch] == NSOrderedSame;
}

@end
