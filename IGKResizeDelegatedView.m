//
//  IGKResizeDelegatedView.m
//  Ingredients
//
//  Created by Alex Gordon on 18/04/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKResizeDelegatedView.h"


@implementation IGKResizeDelegatedView

@synthesize resizeDelegate;

- (void)setFrame:(NSRect)newFrame
{
	[super setFrame:newFrame];
	
	if ([resizeDelegate respondsToSelector:@selector(viewResized:)])
		[resizeDelegate viewResized:self];
}

@end
