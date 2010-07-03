//
//  IGKMattePopUpButton.m
//  Ingredients
//
//  Created by Alex Gordon on 09/03/2010.
//  Written in 2010 by Fileability.
//

#import "IGKMattePopUpButton.h"
#import "NSShadow+MCAdditions.h"
#import "NSBezierPath+MCAdditions.h"

@implementation IGKMattePopUpButtonCell

- (void)drawBezelWithFrame:(NSRect)rect inView:(NSView *)controlView
{
	NSImage *image = [[NSImage alloc] initWithSize:rect.size];
	[image lockFocus];
	
	BOOL isSelected = [self isHighlighted];
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
	
	
	[image unlockFocus];
	
	[image drawInRect:NSMakeRect(0, 0, rect.size.width, rect.size.height)
			 fromRect:NSZeroRect
			operation:NSCompositeSourceOver
			 fraction:[[controlView window] isMainWindow] || [[[controlView window] contentView] isInFullScreenMode] ? 1.0 : 0.75
	   respectFlipped:YES
				hints:nil];
}

@end
