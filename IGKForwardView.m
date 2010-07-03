//
//  IGKForwardView.m
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-05-06.
//  Written in 2010 by SilverCocoa.
//

#import "IGKForwardView.h"


@implementation IGKForwardView


- (id)actionForwardee
{
	BOOL isFullscreen = NO;
	NSWindowController *controller = [[self window] windowController];
	if (!controller || [controller isInFullscreen])
		isFullscreen = YES;
	
	if (isFullscreen)
		return [[[NSApp delegate] kitController] fullscreenWindowController];
	return nil;
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
