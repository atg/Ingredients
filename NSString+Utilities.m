//
//  NSString+Utilities.m
//  Chocolat
//
//  Created by Alex Gordon on 13/07/2009.
//  Copyright 2009 Fileability. All rights reserved.
//

#import "NSString+Utilities.h"
#import "CHSingleFileDocument.h"

NSString *CHDeveloperDirectory()
{
	//FIXME: Add some detection code here and consult preferences. Perhaps check if /Developer/Applications exists and if not, use the path of wherever Xcode is
	return @"/Developer";
}

@implementation NSString (Utilities)

+ (NSString *)computerName
{
	return NSMakeCollectable(SCDynamicStoreCopyComputerName(NULL, NULL));
}
+ (NSString *)volumeName
{
	//return [(NSString *)SCDynamicStoreCopyComputerName(NULL, NULL) autorelease];
	return nil;
}

- (BOOL)startsWith:(NSString *)s
{
	if ([self length] >= [s length] && [[self substringToIndex:[s length]] isEqualToString:s])
		return YES;
	return NO;
}

//For snippets
- (NSString *)evaluatedString
{
	return self;
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

- (NSString *)copiesOf:(NSUInteger)numCopies
{
	NSMutableString *tabAsSpaces = [[NSMutableString alloc] initWithCapacity:numCopies];
	NSUInteger i = 0;
	for (i = 0; i < numCopies; i++)
	{
		[tabAsSpaces appendString:self];
	}
	
	return tabAsSpaces;
}

- (BOOL)caseInsensitiveContains:(NSString *)needle
{
	return [self rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound;
}

- (NSString *)bashQuotedString
{
	// http://muffinresearch.co.uk/archives/2007/01/30/bash-single-quotes-inside-of-single-quoted-strings/
	// ' -> '\''
	
	return [NSString stringWithFormat:@"'%@'", [self stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"]];
}

- (NSRange)rangeOfNearestWordTo:(NSRange)range
{
	// First one of these cool new blocks!
	BOOL (^isValidChar)(unichar c) = ^(unichar c){
		return (BOOL)( (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c == '_') || (c == '$') );
	};
	
	// scan right first to extend the selection
	NSInteger i;
	NSUInteger furthestPointEast = range.location;
	NSUInteger furthestPointWest = range.location;
	
	for (i = range.location; i < [self length]; i++)
	{
		if(!isValidChar([self characterAtIndex:i]))
			break;
		
		furthestPointEast = i + 1;
	}
	
	// scan left now (thanks again moron!)
	for (i = range.location - 1; i >= 0; i--)
	{
		if(!isValidChar([self characterAtIndex:i]))
			break;
		
		furthestPointWest = i;
		
		
		if (i == 0)
			break;
	}
	
	return NSMakeRange(furthestPointWest, furthestPointEast - furthestPointWest);
}

// absolute item path + absolute base path => relative item path
- (NSString *)relativePathRelativeTo:(NSString *)basePath
{
	NSArray *absoluteComponents = [[self pathComponents] mutableCopy];
	[absoluteComponents removeObject:@"/"];
	
	NSArray *relativeComponents = [[basePath pathComponents] mutableCopy];
	[relativeComponents removeObject:@"/"];
	
	//Get the shortest length
	int shortestLength = MIN([absoluteComponents count], [relativeComponents count]);
	
	//Find the point where the two paths diverge
	int lastCommonRoot = -1;
	int i;
	for (i = 0; i < shortestLength; i++)
	{
		NSString *absoluteComponent = [[absoluteComponents objectAtIndex:i] lowercaseString];
		NSString *relativeComponent = [[relativeComponents objectAtIndex:i] lowercaseString];
		
		if ([absoluteComponent isEqual:relativeComponent])
			lastCommonRoot = i;
		else
			break;
	}
	
	//If we didn't find a common prefix, use the absolute path
	if (lastCommonRoot == -1)
		return self;
	
	//Build up the relative path
	NSMutableArray *newPathComponents = [[NSMutableArray alloc] init];
	for (i = lastCommonRoot + 1; i < [relativeComponents count]; i++)
	{
		[newPathComponents addObject:@".."];
	}
	
	for (i = lastCommonRoot + 1; i + 1 < [absoluteComponents count]; i++)
	{
		[newPathComponents addObject:[absoluteComponents objectAtIndex:i]];
	}
	
	[newPathComponents addObject:[absoluteComponents objectAtIndex:[absoluteComponents count] - 1]];
	
	return [NSString pathWithComponents:newPathComponents];
}

- (void)enumerateChars:(void (^)(unichar, BOOL *))block
{
	NSUInteger length = [self length];
	if (length == 0)
		return;
	
	unichar *chars = malloc(sizeof(unichar) * length);
	[self getCharacters:chars range:NSMakeRange(0, length)];
	
	BOOL shouldStop = NO;
	NSUInteger i = 0;
	
	@try
	{
		for (i = 0; i < length; i++)
		{
			block(chars[i], &shouldStop);
			
			if (shouldStop)
				break;
		}
	}
	@catch (NSException * e)
	{
		@throw;
	}
	@finally {
		free(chars);
	}
}

+ (BOOL)ch_isAllowedEncoding:(NSStringEncoding)enc
{
	if (enc == NSASCIIStringEncoding || enc == NSUTF8StringEncoding || enc == NSUTF16StringEncoding || enc == NSUTF32StringEncoding || enc == NSISOLatin1StringEncoding)
		return YES;
	return NO;
}

+ (NSArray *)fileEncodingLocalNames
{
	NSMutableArray *encodings = [[NSMutableArray alloc] init];
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	[encodings addObject:[NSNumber numberWithLongLong:NSASCIIStringEncoding]];
	[array addObject:[NSString localizedNameOfStringEncoding:NSASCIIStringEncoding]];
	
	[encodings addObject:[NSNumber numberWithLongLong:NSUTF8StringEncoding]];
	[array addObject:[NSString localizedNameOfStringEncoding:NSUTF8StringEncoding]];

	[encodings addObject:[NSNumber numberWithLongLong:NSUTF16StringEncoding]];
	[array addObject:[NSString localizedNameOfStringEncoding:NSUTF16StringEncoding]];
	
	[encodings addObject:[NSNumber numberWithLongLong:NSUTF32StringEncoding]];
	[array addObject:[NSString localizedNameOfStringEncoding:NSUTF32StringEncoding]];
	
	[encodings addObject:[NSNumber numberWithLongLong:NSISOLatin1StringEncoding]];
	[array addObject:[NSString localizedNameOfStringEncoding:NSISOLatin1StringEncoding]];
	
	/*
	//A separator item
	[encodings addObject:[NSNull null]];
	[array addObject:[NSNull null]];
	
	NSStringEncoding *encs = [NSString availableStringEncodings];
	while (encs != NULL && *encs != NULL)
	{
		NSStringEncoding enc = *encs;
		if (enc == NSASCIIStringEncoding || enc == NSUTF8StringEncoding ||
			enc == NSUTF16StringEncoding || enc == NSUTF32StringEncoding ||
			enc == NSISOLatin1StringEncoding)
		{
			encs++;
			continue;
		}
		
		[encodings addObject:[NSNumber numberWithLongLong:enc]];
		[array addObject:[NSString localizedNameOfStringEncoding:enc]];
		
		encs++;
	}*/
	
	return [NSMutableArray arrayWithObjects:encodings, array, nil];
}

- (NSString *)convertToLineEndings:(CHNewlineType)t
{
	NSString *CRLFLineEnding = [[NSString alloc] initWithFormat:@"%C%C", 0x000D, 0x000A];
	NSString *CRLineEnding = [[NSString alloc] initWithFormat:@"%C", 0x000D];
	NSString *LFLineEnding = [[NSString alloc] initWithFormat:@"%C", 0x000A];
	
	NSMutableString *returnString = [self mutableCopy];
	
	if (t == CHNewlineTypeCRLF) // CRLF
	{
		[returnString replaceOccurrencesOfString:CRLFLineEnding withString:LFLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])]; // So that it doesn't change CRLineEnding part of CRLFLineEnding
		[returnString replaceOccurrencesOfString:CRLineEnding withString:LFLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:LFLineEnding withString:CRLFLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}
	else if (t == CHNewlineTypeCR) // CR
	{
		[returnString replaceOccurrencesOfString:CRLFLineEnding withString:CRLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:LFLineEnding withString:CRLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}
	else if (t == CHNewlineTypeLF) // LF
	{
		[returnString replaceOccurrencesOfString:CRLFLineEnding withString:LFLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:CRLineEnding withString:LFLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}
	
	return returnString;
}

@end
