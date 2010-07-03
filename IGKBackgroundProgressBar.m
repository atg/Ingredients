//
//  IGKBackgroundProgressBar.m
//  Ingredients
//
//  Created by Alex Gordon on 17/04/2010.
//  Written in 2010 by Fileability.
//

#import "IGKBackgroundProgressBar.h"

//The number of pixels we phase every second
const CGFloat pixelsPerSecond = 60.0;
const CGFloat framesPerSecond = 30.0;

@implementation IGKBackgroundProgressBar

- (id)initWithFrame:(NSRect)frameRect
{
	if (self = [super initWithFrame:frameRect])
	{
		shouldStop = YES;
	}
	
	return self;
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (shouldStop)
		return;
	
	NSRect rect = [self bounds];
	
	NSBezierPath *bp = [NSBezierPath bezierPath];
	NSInteger numX = ceil(rect.size.width / 25.0);
	
	CGFloat bandWidth = 20;
	
	CGFloat h = 0.0;
	
	CGFloat modPhase = round(fmod(phase, rect.size.width));
	CGFloat lastX = -27 + modPhase - rect.size.width;
	
	NSInteger i;
	for (i = -numX; i < numX; i++)
	{
		[bp moveToPoint:NSMakePoint(lastX +0.5, rect.size.height+0.5   - h)];
		[bp lineToPoint:NSMakePoint(lastX + bandWidth+0.5, 0+0.5 + h)];
		[bp lineToPoint:NSMakePoint(lastX + bandWidth + bandWidth+0.5, 0+0.5 + h)];
		[bp lineToPoint:NSMakePoint(lastX + bandWidth+0.5, rect.size.height+0.5 - h)];
		[bp lineToPoint:NSMakePoint(lastX+0.5, rect.size.height+0.5 - h)];
		
		lastX += bandWidth * 2 - 1;
	}
	
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.06] set];
	[bp fill];
}

//FIXME: It would be more reliable to use an NSTimer here 
- (void)doAnimation
{
	if (shouldStop)
		return;
	
	phase += pixelsPerSecond / framesPerSecond;
	
	[self display];
	[self performSelector:@selector(doAnimation) withObject:nil afterDelay:1.0 / framesPerSecond];
}
- (IBAction)startAnimation:(id)sender
{
	shouldStop = NO;
	[self performSelector:@selector(doAnimation) withObject:nil afterDelay:1.0 / framesPerSecond];
}
- (IBAction)stopAnimation:(id)sender
{
	shouldStop = YES;
	[self display]; //-display instead of -setNeedsDisplay: because the main thread may be blocked immediately after this call, so the drawing has to be done *now*
}

@end
