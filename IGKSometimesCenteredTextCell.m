//
//  IGKSometimesCenteredTextCell.m
//  Ingredients
//
//  Created by Alex Gordon on 04/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKSometimesCenteredTextCell.h"


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
 }

@end
