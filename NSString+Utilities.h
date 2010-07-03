//
//  NSString+Utilities.h
//  Chocolat
//
//  Created by Alex Gordon on 13/07/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import <Cocoa/Cocoa.h>


@interface NSString (Utilities)


- (BOOL)startsWith:(NSString *)s;
+ (NSString *)stringByGeneratingUUID;

- (BOOL)containsString:(NSString *)s;
- (BOOL)caseInsensitiveContainsString:(NSString *)s;
- (BOOL)caseInsensitiveHasPrefix:(NSString *)s;
- (BOOL)caseInsensitiveHasSuffix:(NSString *)s;
- (BOOL)isCaseInsensitiveEqual:(NSString *)s;

@end
