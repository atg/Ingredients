//
//  IGKMatteButton.m
//  Ingredients
//
//  Created by Alex Gordon on 19/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IGKMatteButton.h"


@implementation IGKMatteButton

- (void)drawRect:(NSRect)rect
{
	rect = [self bounds];
	
	NSImage *image = [[NSImage alloc] initWithSize:rect.size];
	[image lockFocus];
	
	BOOL isSelected = mouseState != 0;
	float width = rect.size.width;
	
	//Create a bezier path
	const double radius = 4.0;
	
	NSRect strokeRect = NSMakeRect(0, 1, width, rect.size.height - 1.0);
	
	if (!isSelected)
	{
		strokeRect.size.height -= 1.0;
		NSBezierPath *bottomHighlightPath = [NSBezierPath bezierPathWithRoundedRect:strokeRect xRadius:radius yRadius:radius];
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.25] set];
		[bottomHighlightPath fill];
		
		strokeRect.origin.y += 1.0;
		NSBezierPath *strokePath = [NSBezierPath bezierPathWithRoundedRect:strokeRect xRadius:radius yRadius:radius];
		
		NSRect fillRect = NSInsetRect(strokeRect, 1.0, 1.0);
		NSBezierPath *fillHighlightPath = [NSBezierPath bezierPathWithRoundedRect:fillRect xRadius:radius - 1 yRadius:radius - 1];
		fillRect.size.height -= 1.0;
		NSBezierPath *fillPath = [NSBezierPath bezierPathWithRoundedRect:fillRect xRadius:radius - 1 yRadius:radius - 1];
		
		NSGradient *strokeGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.484 green:0.484 blue:0.484 alpha:1.000] endingColor:[NSColor colorWithCalibratedRed:0.484 green:0.484 blue:0.484 alpha:1.000]];	
		[strokeGradient drawInBezierPath:strokePath angle:90];
		
		[[NSColor colorWithCalibratedRed:0.907 green:0.907 blue:0.907 alpha:1.000] set];
		[fillHighlightPath fill];
		
		NSGradient *fillGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.728 green:0.728 blue:0.728 alpha:1.000] endingColor:[NSColor colorWithCalibratedRed:0.878 green:0.878 blue:0.878 alpha:1.000]];	
		[fillGradient drawInBezierPath:fillPath angle:90];
	}
	else
	{
		NSRect pressedRect = strokeRect;
		pressedRect.size.height -= 1.0;
		pressedRect.origin.y += 1.0;
		
		NSBezierPath *pressedPath = [NSBezierPath bezierPathWithRoundedRect:pressedRect xRadius:radius yRadius:radius];
		
		NSShadow *insideShadow = [[NSShadow alloc] initWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] offset:NSMakeSize(0.0, -1.0) blurRadius:4.0];
		
		[[NSColor colorWithCalibratedRed:0.728 green:0.728 blue:0.728 alpha:1.000] set];
		
		[pressedPath fill];
		
		[pressedPath fillWithInnerShadow:insideShadow];
		
		NSGradient *pressedGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.34]
																	endingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.06 + 0.34]];
		
		[pressedGradient drawInBezierPath:pressedPath angle:90];
	}
	
	NSDictionary *titleAttributes = [self titleAttributes];
	NSSize titleSize = [[self title] sizeWithAttributes:titleAttributes];
//	[[self title] drawInRect:NSMakeRect(MAX(ceil([self bounds].size.height / 2.0 - titleSize.height / 2.0), 0), ceil([self bounds].size.height / 2.0 - titleSize.height / 2.0), MIN([self bounds].size.width, titleSize.width), titleSize.height) withAttributes:titleAttributes];
	NSRect titleRect = NSMakeRect(ceil([self bounds].size.width / 2.0 - titleSize.width / 2.0),
	                              floor([self bounds].size.height / 2.0 - titleSize.height / 2.0) + 2,
								  titleSize.width,
								  titleSize.height);
	[[self title] drawInRect:titleRect withAttributes:titleAttributes];
	
	//[[NSColor magentaColor] set];
	//NSRectFillUsingOperation(titleRect, NSCompositeSourceOver);
	
	[image unlockFocus];
	
	[image drawInRect:NSMakeRect(0, 0, rect.size.width, rect.size.height)
			 fromRect:NSZeroRect
			operation:NSCompositeSourceOver
			 fraction:[self isActive] ? 1.0 : 0.75
	   respectFlipped:YES
				hints:nil];
}

- (BOOL)isActive
{
	return [[self window] isMainWindow] || [[[self window] contentView] isInFullScreenMode];
}
- (NSDictionary *)titleAttributes
{
	NSMutableDictionary *attrs = [[NSMutableDictionary alloc] initWithCapacity:4];
	[attrs setValue:[NSFont systemFontOfSize:13] forKey:NSFontAttributeName];
	
	NSShadow *shadow = nil;
	
	if (mouseState == 0)
	{
		shadow = [[NSShadow alloc] initWithColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] offset:NSMakeSize(0, -1) blurRadius:0];
		[attrs setValue:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	}
	else
	{
		shadow = [[NSShadow alloc] initWithColor:[NSColor blackColor] offset:NSMakeSize(0, -1) blurRadius:0];
		[attrs setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	}
	
	[attrs setValue:shadow forKey:NSShadowAttributeName];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	return attrs;
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	
	if (NSPointInRect(p, [self bounds]))
		mouseState = 1;
	else
		mouseState = 0;
	
	if (p.x < 0)
		selectedCell = oldSelectedCell;
	else if (p.x < 34)
		selectedCell = 0;
	else if (p.x < 63)
		selectedCell = 1;
	else if (p.x < 91)
		selectedCell = 2;
	else
		selectedCell = oldSelectedCell;
	
	[self setNeedsDisplay:YES];
}
- (void)mouseDragged:(NSEvent *)event
{
	[self mouseDown:event];
}
- (void)mouseUp:(NSEvent *)event
{
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	
	if (selectedCell == -1 || selectedCell == oldSelectedCell)
	{
		selectedCell = oldSelectedCell;
	}
	else
	{
		oldSelectedCell = selectedCell;
		
		if (NSPointInRect(p, [self bounds]))
			if ([[self target] respondsToSelector:[self action]])
				[[self target] performSelector:[self action]];
	}
	
	mouseState = 0;
	
	[self setNeedsDisplay:YES];
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
