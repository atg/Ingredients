//
//  IGKSometimesCenteredTextCell.m
//  Ingredients
//
//  Created by Alex Gordon on 04/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKSometimesCenteredTextCell.h"


@implementation IGKSometimesCenteredTextCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    cellFrame.origin.y += [self tag];
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}


@end
