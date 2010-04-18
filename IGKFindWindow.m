//
//  IGKFindWindow.m
//  Ingredients
//
//  Created by Alex Gordon on 18/04/2010.
//  Copyright 2010 Fileability. All rights reserved.
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

/*
- (BOOL)resignFirstResponder
{
	if (![self parentWindow])
		return;
	if (ignoreResponderChanges)
		return;
	
	[controller setShown:NO];
	return [super resignFirstResponder];
}

- (void)resignMainWindow
{
	if (![self parentWindow])
		return;
	if (ignoreResponderChanges)
		return;
	
	[controller setShown:NO];
	[super resignMainWindow];
}
*/

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
