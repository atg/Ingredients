//
//  IGKForwardView.m
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-05-06.
//  Copyright 2010 SilverCocoa. All rights reserved.
//

#import "IGKForwardView.h"


@implementation IGKForwardView


- (id)actionForwardee
{
	return [[[NSApp delegate] kitController] fullscreenWindowController];
}
- (BOOL)respondsToSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
		return YES;
	if ([[self actionForwardee] respondsToSelector:aSelector])
		return YES;
	return NO;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
		return [super methodSignatureForSelector:aSelector];
	
	id forwardee = [self actionForwardee];
	if ([forwardee respondsToSelector:aSelector])
		return [forwardee methodSignatureForSelector:aSelector];
	
	return [super methodSignatureForSelector:aSelector];
}
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	id forwardee = [self actionForwardee];
	
	if ([forwardee respondsToSelector:[anInvocation selector]])
	{
		[anInvocation invokeWithTarget:forwardee];
	}
	else
	{
		[super forwardInvocation:anInvocation];
	}
}



@end
