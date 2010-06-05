//
//  IGKSometimesCenteredTextCell.m
//  Ingredients
//
//  Created by Alex Gordon on 04/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKSometimesCenteredTextCell.h"


@implementation IGKStrikethroughTextCell

+ (void)drawStrikethroughInRect:(NSRect)rect
{
	[[NSColor redColor] set];
	
	rect.origin.y = rect.size.height / 2.0;
	rect.size.height = 1.0;
	
	NSRectFillUsingOperation(rect, NSCompositeSourceOver);
}

@end

@implementation IGKSometimesCenteredTextCell

/*
- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y += [self tag];
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}
 */


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	cellFrame.origin.y += [self tag];
	[super drawWithFrame:cellFrame inView:controlView];
	
	if (hasStrikethrough)
		[self drawStrikethroughInRect:cellFrame];
}


@end

@implementation IGKSometimesCenteredTextCell2

 - (NSRect)titleRectForBounds:(NSRect)theRect {
	 NSRect titleFrame = [super titleRectForBounds:theRect];
	 NSSize titleSize = [[self attributedStringValue] size];
	 titleFrame.origin.y += [self tag];
	 return titleFrame;
 }
 
 - (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	 NSRect titleRect = [self titleRectForBounds:cellFrame];
	 [[self attributedStringValue] drawInRect:titleRect];
	 if (hasStrikethrough)
		 [self drawStrikethroughInRect:cellFrame];
 }

@end
