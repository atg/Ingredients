//
//  IGKSourceListWallpaperView.m
//  Ingredients
//
//  Created by Alex Gordon on 10/02/2010.
//  Written in 2010 by Fileability.
//

#import "IGKSourceListWallpaperView.h"
#import "NSShadow+MCAdditions.h"
#import "NSBezierPath+MCAdditions.h"
#import "IGKLaunchController.h"


@implementation IGKSourceListWallpaperView

@synthesize progressValue;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexedNewPaths:) name:@"IGKHasIndexedNewPaths" object:nil];
    }
    return self;
}

- (void)indexedNewPaths:(NSNotification *)notif
{
	IGKLaunchController *lc = [notif object];
	
	progressValue = [lc fraction];
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect rect = [self bounds];
	
	NSImage *wallpaperImage = [NSImage imageNamed:@"sourcelist_indexing_wallpaper"];
	NSColor *wallpaperColor = [NSColor colorWithPatternImage:wallpaperImage];
	
	[wallpaperColor set];
	NSRectFillUsingOperation(rect, NSCompositeSourceOver);
	
	NSBezierPath *bp = [NSBezierPath bezierPathWithRect:rect];
	[bp fillWithInnerShadow:[[NSShadow alloc] initWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.25] offset:NSMakeSize(0, -1.0) blurRadius:10.0]];
	
	
	//This should probably be in an NSProgressIndicator subclass, but I CBA to do that for something that will appear for all of 10 seconds.
	if (progressValue < 0.01)
		return;
	
	NSShadow *barShadow = [[NSShadow alloc] initWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] offset:NSMakeSize(0, -1.0) blurRadius:0.0];
	[barShadow set];
	
	NSRect outlineRect = NSMakeRect(11.0, rect.size.height / 2.0 - 9.0, rect.size.width - 22.0, 18.0);
	
	NSBezierPath *outlinePath = [NSBezierPath bezierPathWithRoundedRect:outlineRect xRadius:9.0 yRadius:9.0];
	[outlinePath setLineWidth:2.0];
	[[NSColor whiteColor] set];
	[outlinePath stroke];
		
	NSRect progressRect = NSMakeRect(13.0, outlineRect.origin.y + 2.0, rect.size.width - 26.0, 14.0);
	
	NSRect clipRect = progressRect;
	clipRect.size.width *= progressValue;
	clipRect.size.width = floor(clipRect.size.width);
	
	[[NSBezierPath bezierPathWithRect:clipRect] addClip];
	
	NSBezierPath *progressPath = [NSBezierPath bezierPathWithRoundedRect:progressRect xRadius:7.0 yRadius:7.0];
	[progressPath fill];
	
}

- (BOOL)isFlipped
{
	return YES;
}

@end
