//
//  IGKResizeDelegatedView.m
//  Ingredients
//
//  Created by Alex Gordon on 18/04/2010.
//  Written in 2010 by Fileability.
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
