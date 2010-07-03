//
//  CHLeftSplitView.m
//  Chocolat
//
//  Created by Alex Gordon on 29/10/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import "CHLeftSplitView.h"
#import <QuartzCore/QuartzCore.h>


@implementation CHLeftSplitView

@synthesize enabled;

- (id)animationForKey:(NSString *)key
{
	CAAnimation *animation = [super animationForKey:key];
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	return animation;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		enabled = YES;
    }
    return self;
}
- (void)awakeFromNib
{
	enabled = YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (enabled)
		[super mouseDown:theEvent];
}
- (void)mouseDragged:(NSEvent *)theEvent
{
	if (enabled)
		[super mouseDragged:theEvent];
}
- (void)mouseUp:(NSEvent *)theEvent
{
	if (enabled)
		[super mouseUp:theEvent];
}
- (void)mouseEntered:(NSEvent *)theEvent
{
	if (enabled)
		[super mouseEntered:theEvent];
}
- (void)mouseExited:(NSEvent *)theEvent
{
	if (enabled)
		[super mouseExited:theEvent];
}
- (void)mouseMoved:(NSEvent *)theEvent
{
	if (enabled)
		[super mouseMoved:theEvent];
}
- (void)cursorUpdate:(NSEvent *)theEvent
{
	if (enabled)
		[super cursorUpdate:theEvent];
}


@end
