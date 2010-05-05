//
//  NSString+Utilities.h
//  Chocolat
//
//  Created by Alex Gordon on 13/07/2009.
//  Copyright 2009 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>

NSString *CHDeveloperDirectory();

@interface NSString (Utilities)

+ (NSString *)computerName;
+ (NSString *)volumeName;

- (BOOL)startsWith:(NSString *)s;
+ (NSString *)stringByGeneratingUUID;

- (NSString *)copiesOf:(NSUInteger)numCopies;

- (BOOL)caseInsensitiveContains:(NSString *)needle;

- (NSString *)bashQuotedString;

- (NSRange)rangeOfNearestWordTo:(NSRange)range;

- (NSString *)relativePathRelativeTo:(NSString *)basePath;

- (void)enumerateChars:(void (^)(unichar, BOOL *))block;

@end
