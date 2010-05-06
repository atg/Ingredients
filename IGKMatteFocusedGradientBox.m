//
//  IGKMatteFocusedGradientBox.m
//  Ingredients
//
//  Created by Alex Gordon on 20/04/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKMatteFocusedGradientBox.h"


@implementation IGKMatteFocusedGradientBox

- (BOOL)isActive
{
	return [[self window] isMainWindow] || [[[self window] contentView] isInFullScreenMode];
}
- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	if (![self isActive])
	{
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
		NSRectFillUsingOperation([self bounds], NSCompositeSourceOver);
	}
}

- (void)viewWillMoveToWindow:(NSWindow *)window
{
	if (window)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:window];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
	}
}
- (void)windowDidBecomeMain:(NSNotification *)notif
{	
	[self setNeedsDisplay:YES];
}
- (void)windowDidResignMain:(NSNotification *)notif
{	
	[self setNeedsDisplay:YES];
}

@end
