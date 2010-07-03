//
//  IGKNoSelectionInnerView.m
//  Ingredients
//
//  Created by Alex Gordon on 13/02/2010.
//  Written in 2010 by Fileability.
//

#import "IGKNoSelectionInnerView.h"


@implementation IGKNoSelectionInnerView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	NSRect rect = [self bounds];
	
	NSBezierPath *outerBp = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:10 yRadius:10];
	[[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.00] set];
	[outerBp fill];
	
	NSBezierPath *innerBp = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 1, 1) xRadius:9 yRadius:9];
	NSGradient *grad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.85 green:0.85 blue:0.85 alpha:1.00]
													 endingColor:[NSColor colorWithCalibratedRed:0.91 green:0.91 blue:0.91 alpha:1.00]];
	[grad drawInBezierPath:innerBp angle:90];
}

@end
