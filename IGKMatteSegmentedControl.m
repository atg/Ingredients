//
//  IGKMatteSegmentedControl.m
//  Ingredients
//
//  Created by Alex Gordon on 27/02/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IGKMatteSegmentedControl.h"

@interface IGKMatteSegmentedControl ()

- (float)igk_drawSegment:(NSUInteger)segment runningY:(float)runningY;

@end


@implementation IGKMatteSegmentedControl

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    rect = [self bounds];
	
	NSUInteger selseg = [self selectedSegment];
	
	int i;
	float runningY = 0.0;
	float sely = 0.0;
	for (i = 0; i < [self segmentCount]; i++)
	{
		float width = [self widthForSegment:i];
		
		if (i != selseg)
			[self igk_drawSegment:i runningY:runningY];
		else
			sely = runningY;
		
		runningY += width - 1.0;
	}
	
	if (selseg != -1)
		[self igk_drawSegment:selseg runningY:sely];
}
- (float)igk_drawSegment:(NSUInteger)segment runningY:(float)runningY
{
	BOOL isLeft = (segment == 0);
	BOOL isRight = (segment + 1 == [self segmentCount]);
	
	float width = [self widthForSegment:segment];
	BOOL isSelected = ([self selectedSegment] == segment);
	
	if (isLeft)
	{
		width += 1.0;
	}
	
	width += 1.0;
	
	//Create a bezier path
	const double radius = 4.0;
	
	NSRect strokeRect = NSMakeRect(runningY, 0, width, [self bounds].size.height);
	
	NSBezierPath *strokePath = [[self class] roundedBezierInRect:strokeRect radius:radius hasLeft:isLeft hasRight:isRight];
	NSBezierPath *fillPath = [[self class] roundedBezierInRect:NSInsetRect(strokeRect, 1.0, 1.0) radius:radius - 1 hasLeft:isLeft hasRight:isRight];
		
	NSGradient *strokeGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.867 - 0.2 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.98 - 0.2 alpha:1.00]];	
	[strokeGradient drawInBezierPath:strokePath angle:90];
	
	NSGradient *fillGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.867 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.98 green:0.98 blue:0.98 alpha:1.00]];	
	[fillGradient drawInBezierPath:fillPath angle:isSelected ? 90 : 90];
	
	if (isSelected)
	{
		NSShadow *insideShadow = [[NSShadow alloc] initWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] offset:NSMakeSize(0.0, -1.0) blurRadius:3.0];//;
		[strokePath fillWithInnerShadow:insideShadow];
	}
	
	
	//Calculate the Y coord of the next segment	
	return runningY + width - 1.0;
}
+ (NSBezierPath *)roundedBezierInRect:(NSRect)rect radius:(float)radius hasLeft:(BOOL)hasLeft hasRight:(BOOL)hasRight
{
	NSBezierPath *b = [NSBezierPath bezierPath];
	
	NSPoint bottomLeft = rect.origin;
	NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
	NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
	NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
	
	
	/*if (hasLeft && !hasRight)
	{
		[b moveToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
		[b appendBezierPathWithArcFromPoint:topLeft toPoint:bottomLeft radius:radius];
		[b appendBezierPathWithArcFromPoint:bottomLeft toPoint:bottomRight radius:radius];

	}
	else
		[b moveToPoint:topLeft];
	*/
	
	if (hasLeft)
		[b moveToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
	else
		[b moveToPoint:topLeft];
	
	if (hasLeft)
		[b appendBezierPathWithArcFromPoint:topLeft toPoint:bottomLeft radius:radius];
	else
		[b lineToPoint:bottomLeft];
	
	if (hasLeft)
		[b appendBezierPathWithArcFromPoint:bottomLeft toPoint:bottomRight radius:radius];
	else
		[b appendBezierPathWithArcFromPoint:bottomLeft toPoint:bottomRight radius:radius];
	
	if (hasRight)
		[b appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight radius:radius];
	else
		[b lineToPoint:bottomRight];
	
	if (hasRight)
		[b appendBezierPathWithArcFromPoint:topRight toPoint:topLeft radius:radius];
	else
		[b lineToPoint:topRight];
	
	[b closePath];
	
	return b;
}






























- (void)drawSegmentDivider:(NSUInteger)segmentIndex isSelected:(BOOL)isSelected runningX:(float)runningX
{
	NSRect rect = [self bounds];
	
	NSRect dividerRect = NSMakeRect(runningX, 0, 1.0, [self bounds].size.height);
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.867 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.98 green:0.98 blue:0.98 alpha:1.00]];
	NSColor *boxShadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.6];
	NSColor *borderColor = [NSColor colorWithCalibratedWhite:0.55 alpha:0.75];
	NSColor *textColor = [NSColor colorWithCalibratedWhite:0.05 alpha:1.0];
	NSColor *shadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.75];
	
	NSRect gradientRect = dividerRect;
	gradientRect.size.height -= 1.0;
	gradientRect.origin.y += 1.0;
	
	[gradient drawInRect:gradientRect angle:90];
	
	if (!isSelected)
	{
		[borderColor set];
		NSRectFillUsingOperation(gradientRect, NSCompositeSourceOver);
	}
	else
	{
		[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
		NSRectFillUsingOperation(gradientRect, NSCompositeSourceOver);
		
		/*
		 [borderColor set];
		 NSRectFillUsingOperation(NSMakeRect(gradientRect.origin.x, 1, 1, 1), NSCompositeSourceOver);
		 NSRectFillUsingOperation(NSMakeRect(gradientRect.origin.x, gradientRect.size.height, 1, 1), NSCompositeSourceOver);
		 */
	}
	
	NSRect shadowRect = dividerRect;
	shadowRect.size.height = 1.0;
	[shadowColor set];
	NSRectFillUsingOperation(shadowRect, NSCompositeSourceOver);
}
- (float)drawSegmentSegment:(NSUInteger)segmentIndex isSelected:(BOOL)isSelected runningX:(float)runningX
{
	NSRect rect = [self bounds];
	
	NSRect segmentRect = NSMakeRect(runningX, 0, floor((rect.size.width - 1) / 2.0), [self bounds].size.height);
	[NSGraphicsContext saveGraphicsState];
	[[NSBezierPath bezierPathWithRect:segmentRect] addClip];
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.867 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.98 green:0.98 blue:0.98 alpha:1.00]];
	NSColor *boxShadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.6];
	NSColor *borderColor = [NSColor colorWithCalibratedWhite:0.55 alpha:0.75];
	NSColor *textColor = [NSColor colorWithCalibratedWhite:0.05 alpha:1.0];
	NSColor *shadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.75];
	
	const double radius = 3.0;
	
	NSBezierPath *bp = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
	
	if (isSelected)
	{
		//Box Shadow
		NSRect boxShadowRect = rect;
		boxShadowRect.size.height -= 1.0;
		NSBezierPath *boxShadowPath = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
		
		[boxShadowColor set];
		[boxShadowPath fill];
		
		//Outside Stroke
		NSRect boxRect = rect;
		boxRect.size.height -= 1.0;
		boxRect.origin.y += 1.0;
		NSGradient *strokeGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.27 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.51 alpha:1.0]];
		NSBezierPath *strokeShadowPath = [NSBezierPath bezierPathWithRoundedRect:boxRect xRadius:radius yRadius:radius];
		
		[strokeGradient drawInBezierPath:strokeShadowPath angle:270];
		
		//Inside Fill
		NSGradient *insideGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.655 alpha:1.0]];
		NSBezierPath *insidePath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(boxRect, 1.0, 1.0) xRadius:radius - 1.0 yRadius:radius - 1.0];
		
		[insideGradient drawInBezierPath:insidePath angle:90];
		
		//Inner Shadow
		NSShadow *insideShadow = [[NSShadow alloc] initWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] offset:NSMakeSize(0.0, -1.0) blurRadius:3.0];//;
		[insidePath fillWithInnerShadow:insideShadow];
		
		rect.origin.x += 0.5;
		rect.origin.y += 0.5;
		rect.size.width -= 1.0;
		rect.size.height -= 1.0;
	}
	else
	{			
		rect.origin.x += 0.5;
		rect.origin.y += 0.5;
		rect.size.width -= 1.0;
		rect.size.height -= 1.0;
		
		//Box shadow
		NSRect boxShadowRect = rect;
		boxShadowRect.size.height -= 1.0;
		NSBezierPath *boxShadowPath = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
		
		[boxShadowColor set];
		[boxShadowPath stroke];
		
		//Normal Fill
		NSRect boxRect = rect;
		boxRect.size.height -= 1.0;
		boxRect.origin.y += 1.0;
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:boxRect xRadius:radius yRadius:radius];
		
		[gradient drawInBezierPath:path angle:(isSelected ? 270 : 90)];
		
		[borderColor set];
		[path stroke];
	}
	
	[NSGraphicsContext restoreGraphicsState];
	return segmentRect.size.width;
}
- (void)drawBackground:(BOOL)selected
{	
	NSRect rect = [self bounds];
	
	NSUInteger segCount = [self segmentCount];
	NSInteger selSeg = [self selectedSegment];
	NSUInteger i = 0;
	
	float runningX = 0.0;
	for (i = 0; i < segCount; i++)
	{
		runningX += [self drawSegmentSegment:i isSelected:i == selSeg runningX:runningX];
		
		if (i < segCount)
		{	
			BOOL isSelected = YES;
			if (selSeg == -1)
				isSelected = NO;
			
			[self drawSegmentDivider:i isSelected:isSelected runningX:runningX];
		}
		
		runningX += 1.0;
	}
}

- (void)drawRect_old:(NSRect)rect
{
    rect = [self bounds];
	
	[NSGraphicsContext saveGraphicsState];
	
	int i;
	for (i = 0; i < [self segmentCount]; i++)
	{
		CGFloat w = rect.size.width/[self segmentCount];
		NSRect segmentRect = NSMakeRect(i * w, 0, w, rect.size.height);
		//[NSBezierPath clipRect:segmentRect];
		
		[self drawBackground:[self selectedSegment] == i];
		
		[[NSBezierPath bezierPathWithRect:rect] addClip];
		
		if (i + 1 < [self segmentCount])
		{
			NSGradient *strokeGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.27 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.51 alpha:1.0]];
			[strokeGradient drawInRect:NSMakeRect(round((i + 1) * w), 1, 1, rect.size.height - 1) angle:270];
		}
	}
	
	for (i = 0; i < [self segmentCount]; i++)
	{
		NSImage *img = [self imageForSegment:i];
		[img compositeToPoint:NSMakePoint(round((rect.size.width/2)*i + 11), 7) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

- (BOOL)isFlipped
{
	return NO;
}

@end
