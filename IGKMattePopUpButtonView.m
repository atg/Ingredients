//
//  IGKMattePopUpButtonView.m
//  Ingredients
//
//  Created by Alex Gordon on 20/04/2010.
//  Written in 2010 by Fileability.
//

#import "IGKMattePopUpButtonView.h"


@implementation IGKMattePopUpButtonView

- (void)drawRect:(NSRect)dirtyRect
{
	[NSGraphicsContext saveGraphicsState];
	CGContextSetAlpha([[NSGraphicsContext currentContext] graphicsPort], [self isActive] ? 1.0 : 0.7);
	
	//NSRect rect = [self bounds];
	//NSImage *image = [[NSImage alloc] initWithSize:rect.size];
	//[image lockFocus];
	
	[super drawRect:dirtyRect];
		/*
	[image unlockFocus];
	
	[image drawInRect:NSMakeRect(0, 0, rect.size.width, rect.size.height)
			 fromRect:NSZeroRect
			operation:NSCompositeSourceOver
			 fraction:[[self window] isMainWindow] ? 1.0 : 0.7
	   respectFlipped:YES
				hints:nil];*/
	
	[NSGraphicsContext restoreGraphicsState];
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
