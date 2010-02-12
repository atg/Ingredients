//
//  NSShadow+MCAdditions.h
//
//  Created by Sean Patrick O'Brien on 4/3/08.
//  Copyright 2008 MolokoCacao. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSShadow (MCAdditions)

- (id)initWithColor:(NSColor *)color offset:(NSSize)offset blurRadius:(CGFloat)blur;

@end
