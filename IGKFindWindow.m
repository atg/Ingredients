//
//  IGKFindWindow.m
//  Ingredients
//
//  Created by Alex Gordon on 18/04/2010.
//  Written in 2010 by Fileability.
//

#import "IGKFindWindow.h"


@implementation IGKFindWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag])
	{
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		[self setHasShadow:NO];
	}
	
	return self;
}


//This is a bit of a hack to ensure the parent's window controller gets action messages. We forward everything we don't respond to, to the parent's window controller
- (id)actionForwardee
{
	return [[self parentWindow] windowController];
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

- (void)becomeKeyWindow
{
	[super becomeKeyWindow];
	
	//If this window becomes key, we should make the parent window main
	if ([[self parentWindow] canBecomeMainWindow])
		[[self parentWindow] makeMainWindow];
}
- (void)becomeMainWindow
{
	[super becomeMainWindow];
	
	//Ditto here. For some reason Apple sends -becomeKeyWindow first then -becomeMainWindow
	if ([[self parentWindow] canBecomeMainWindow])
		[[self parentWindow] makeMainWindow];
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}
- (BOOL)canBecomeMainWindow
{
	return YES;
}
- (BOOL)acceptsFirstResponder
{
	return YES;
}


@end
