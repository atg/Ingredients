//
//  IGKMattePopUpButtonView.m
//  Ingredients
//
//  Created by Alex Gordon on 20/04/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKMattePopUpButtonView.h"


@implementation IGKMattePopUpButtonView

- (void)drawRect:(NSRect)dirtyRect
{
	[NSGraphicsContext saveGraphicsState];
	CGContextSetAlpha([[NSGraphicsContext currentContext] graphicsPort], [self isActive] ? 1.0 : 0.7);
	
	//NSRect rect = [self bounds];
	//NSImage *image = [[NSImage alloc] initWithSize:rect.size];
	//[image lockFocus];
	
	[super drawRect:dirtyRect];
		/*
	[image unlockFocus];
	
	[image drawInRect:NSMakeRect(0, 0, rect.size.width, rect.size.height)
			 fromRect:NSZeroRect
			operation:NSCompositeSourceOver
			 fraction:[[self window] isMainWindow] ? 1.0 : 0.7
	   respectFlipped:YES
				hints:nil];*/
	
	[NSGraphicsContext restoreGraphicsState];
}
- (BOOL)isActive
{
	return [[self window] isMainWindow] || [[[self window] contentView] isInFullScreenMode];
}

@end
