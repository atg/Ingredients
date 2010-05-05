//
//  NSString+Utilities.h
//  Chocolat
//
//  Created by Alex Gordon on 13/07/2009.
//  Copyright 2009 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (Utilities)


- (BOOL)startsWith:(NSString *)s;
+ (NSString *)stringByGeneratingUUID;


@end
