//
//  IGKMultiSelector.m
//  Ingredients
//
//  Created by Alex Gordon on 22/02/2010.
//  Written in 2010 by Fileability.
//

#import "IGKMultiSelector.h"


@implementation IGKMultiSelector

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (int)selectedCell
{
	return selectedCell;
}
- (void)setSelectedCell:(int)newSelectedCell
{
	selectedCell = newSelectedCell;
	oldSelectedCell = newSelectedCell;
	
	[self setNeedsDisplay:YES];
}

- (BOOL)isActive
{
	return [[self window] isMainWindow] || [[[self window] contentView] isInFullScreenMode];
}
- (void)drawRect:(NSRect)rect
{
	rect = [self bounds];
	
	BOOL isMain = [self isActive];
	
	NSDrawThreePartImage(rect,
						 [NSImage imageNamed:@"MultiSel_window_frame_button_active_left"],
						 [NSImage imageNamed:@"MultiSel_window_frame_button_active_middle"],
						 [NSImage imageNamed:@"MultiSel_window_frame_button_active_right"],
						 NO, NSCompositeSourceOver, (isMain ? 1.0 : 0.7), YES);
	
	/*
	if (mouseState == 1)
	{
		NSDrawThreePartImage(rect, [NSImage imageNamed:@"MultiSel_window_frame_button_active_left"],
							 [NSImage imageNamed:@"MultiSel_window_frame_button_active_middle"],
							 [NSImage imageNamed:@"MultiSel_window_frame_button_active_right"],
							 NO, NSCompositeSourceOver, 0.5, YES);
	}
	*/
	
	//Draw dividers
	NSImage *dividerImage = [NSImage imageNamed:@"MultiSel_Divider"];
	[dividerImage drawAtPoint:NSMakePoint(32 - 4, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(isMain ? 1.0 : 0.7 * 1.0)];
	[dividerImage drawAtPoint:NSMakePoint(61 - 4, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(isMain ? 1.0 : 0.7 * 1.0)];
	
	//Draw icons
	
	//No Search
	[self drawCellNamed:@"NoSearch" point:NSMakePoint(11, 3) index:0];
	[self drawCellNamed:@"SideSearch" point:NSMakePoint(40, 3) index:1];
	[self drawCellNamed:@"AdvSearch" point:NSMakePoint(69, 3) index:2];
	
	
	
	/*
	NSImage *icon = [self image];
	NSSize size = [icon size];
	NSPoint point = NSMakePoint(round(rect.size.width / 2 - size.width / 2) + 2, round(rect.size.height / 2 - size.height / 2));
	[icon setFlipped:YES];
	[icon drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(isMain ? 1.0 : 0.7)];
	 */
}
- (void)drawCellNamed:(NSString *)name point:(NSPoint)point index:(int)index
{
	NSString *subtype = @"Norm";
	if (selectedCell == index)
	{
		if (mouseState == 1)
			subtype = @"NormHov";
		else
			subtype = @"Sel";
	}
	
	NSString *imageName = [NSString stringWithFormat:@"MultiSel_%@_%@", name, subtype];
	NSImage *image = [NSImage imageNamed:imageName];
	
	NSRect rect;
	rect.origin = point;
	rect.size = [image size];
	
	[image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	
	if (NSPointInRect(p, [self bounds]))
		mouseState = 1;
	else
		mouseState = 0;
	
	if (p.x < 0)
		selectedCell = oldSelectedCell;
	else if (p.x < 34)
		selectedCell = 0;
	else if (p.x < 63)
		selectedCell = 1;
	else if (p.x < 91)
		selectedCell = 2;
	else
		selectedCell = oldSelectedCell;
	
	[self setNeedsDisplay:YES];
}
- (void)mouseDragged:(NSEvent *)event
{
	[self mouseDown:event];
}
- (void)mouseUp:(NSEvent *)event
{
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	
	if (selectedCell == -1 || selectedCell == oldSelectedCell)
	{
		selectedCell = oldSelectedCell;
	}
	else
	{
		oldSelectedCell = selectedCell;
		
		if (NSPointInRect(p, [self bounds]))
			if ([[self target] respondsToSelector:[self action]])
				[[self target] performSelector:[self action]];
	}
	
	mouseState = 0;
	
	[self setNeedsDisplay:YES];
}


@end
