//
//  IGKFindBackgroundView.m
//  Ingredients
//
//  Created by Alex Gordon on 17/04/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKFindBackgroundView.h"


@implementation IGKFindBackgroundView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect rect = [self bounds];
	
	float radius = 5.0;
	
	NSRect boxRect = rect;
	boxRect.size.height += radius + 8.0;
	
	NSBezierPath *strokePath = [NSBezierPath bezierPathWithRoundedRect:boxRect xRadius:radius yRadius:radius];
	[[NSColor colorWithCalibratedWhite:0.56 alpha:1.0] set];
	[strokePath fill];
	
	NSBezierPath *fillPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(boxRect, 1.0, 1.0) xRadius:radius - 1.0 yRadius:radius - 1.0];
	[[NSColor colorWithCalibratedWhite:0.82 alpha:1.0] set];
	[fillPath fill];
}

@end
