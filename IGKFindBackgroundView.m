//
//  IGKFindBackgroundView.m
//  Ingredients
//
//  Created by Alex Gordon on 17/04/2010.
//  Written in 2010 by Fileability.
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
	if ([self isActive])
		[[NSColor colorWithCalibratedWhite:0.56 alpha:1.0] set];
	else
		[[NSColor colorWithCalibratedWhite:0.577 alpha:1.000] set];
	
	[strokePath fill];
	
	NSBezierPath *fillPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(boxRect, 1.0, 1.0) xRadius:radius - 1.0 yRadius:radius - 1.0];
	if ([self isActive])
		[[NSColor colorWithCalibratedWhite:0.82 alpha:1.0] set];
	else
		[[NSColor colorWithCalibratedWhite:0.859 alpha:1.000] set];
	
	[fillPath fill];
}

#pragma mark Redrawing when the parent window becomes Active/Inactive

- (void)viewDidMoveToParentWindow:(NSWindow *)parentWindow
{
	if (parentWindow)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:parentWindow];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:parentWindow];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:parentWindow];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:parentWindow];
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
- (BOOL)isActive
{
	return [[[self window] parentWindow] isMainWindow] || [[[[self window] parentWindow] contentView] isInFullScreenMode];
}

@end
