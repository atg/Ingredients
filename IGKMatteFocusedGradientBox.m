//
//  IGKMatteFocusedGradientBox.m
//  Ingredients
//
//  Created by Alex Gordon on 20/04/2010.
//  Written in 2010 by Fileability.
//

#import "IGKMatteFocusedGradientBox.h"


@implementation IGKMatteFocusedGradientBox

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	if (![self isActive])
	{
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
		NSRectFillUsingOperation([self bounds], NSCompositeSourceOver);
	}
}


#pragma mark Redrawing when the window becomes Active/Inactive

- (void)viewWillMoveToWindow:(NSWindow *)window
{
	//NSLog(@"viewWillMoveToWindow: %d", [self isActive]);
	
	if (window)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeKeyNotification object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignKeyNotification object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:window];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
	}
	
	[self setNeedsDisplay:YES];
}
- (void)viewDidMoveToWindow
{
	[self setNeedsDisplay:YES];
}
- (void)windowDidBecomeMain:(NSNotification *)notif
{	
	[self setNeedsDisplay:YES];
}
- (void)windowDidResignMain:(NSNotification *)notif
{	
	[self setNeedsDisplay:YES];
}
- (BOOL)isActive
{
	return [[self window] isMainWindow] || ([NSStringFromClass([[self window] class]) isEqual:@"_NSFullScreenWindow"] && [[self window] isKeyWindow]);
}

@end
