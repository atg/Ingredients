//
//  NSShadow+MCAdditions.m
//
//  Created by Sean Patrick O'Brien on 4/3/08.
//  Copyright 2008 MolokoCacao. Written in 2010 by Fileability..
//

#import "NSShadow+MCAdditions.h"


@implementation NSShadow (MCAdditions)

- (id)initWithColor:(NSColor *)color offset:(NSSize)offset blurRadius:(CGFloat)blur
{
	self = [self init];
	
	if (self != nil) {
		[self setShadowColor:color];
		[self setShadowOffset:offset];
		[self setShadowBlurRadius:blur];
	}
	
	return self;
}

@end
