//
//  XBNewSourceListCell.m
//  SourceList3
//
//  Created by Alex Gordon on 16/01/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import "XBNewSourceListCell.h"


#pragma mark Globals

NSString *const XBSourceListLabelRed = @"red";
NSString *const XBSourceListLabelOrange = @"orange";
NSString *const XBSourceListLabelYellow = @"yellow";
NSString *const XBSourceListLabelGreen = @"green";
NSString *const XBSourceListLabelBlue = @"blue";
NSString *const XBSourceListLabelPurple = @"purple";
NSString *const XBSourceListLabelGray = @"gray";
NSString *const XBSourceListLabelClear = @"clear";
NSString *const XBSourceListLabelNA = @"n/a";

const float actionButtonDiameter = 14.0;
const float actionButtonMargin = 3.0;



@implementation XBNewSourceListCell


#pragma mark Properties

@synthesize tableView;
@synthesize label;
@synthesize isHighlighted;
@synthesize image;
@synthesize alternateImage;
@synthesize actionButtonState;
@synthesize hasAddButton;
@synthesize hasCloseButton;



#pragma mark Methods

/*
- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
	actionButtonState = 2;
	
	return YES;
}
- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
	return YES;
}
- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	if (flag)
		actionButtonState = 1;
}
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
	return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

- (void)mouseMoved:(NSPoint)point cellFrame:(NSRect)rect
{
	
}
- (void)mouseDown:(NSPoint)point clickCount:(unsigned)clickCount isRightButton:(BOOL)isRightButton
{
	
}
- (void)mouseDragged:(NSPoint)point clickCount:(unsigned)clickCount isRightButton:(BOOL)isRightButton
{
	
}
- (void)mouseUp:(NSPoint)point clickCount:(unsigned)clickCount isRightButton:(BOOL)isRightButton
{
	
}
*/

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	BOOL oldIsHighlighted = isHighlighted;
	isHighlighted = YES;
	[self drawWithFrame:cellFrame inView:controlView];
	isHighlighted = oldIsHighlighted;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	/*
	if ([label isEqual:XBSourceListLabelNA])
	{
		float offset = 0;
		
		NSRect labelRect = cellFrame;
		
		if (hasAddButton)
		{
			labelRect.size.height -= 2;
			labelRect.origin.y += 1;
			if (actionButtonState != 0)
				labelRect.size.width -= actionButtonDiameter + 2*actionButtonMargin - 2.0;
			
			if (actionButtonState != 0)
			{
				//Draw circle
				NSRect circleRect = NSMakeRect(cellFrame.origin.x + cellFrame.size.width - actionButtonMargin - actionButtonDiameter + 2.0, cellFrame.origin.y + actionButtonMargin, actionButtonDiameter, actionButtonDiameter);
				
				//Draw Cog
				NSRect cogRect = circleRect;
				NSImage *cog = nil;
				
				if ([[controlView window] isMainWindow])
				{
					if (isHighlighted)
					{
						if (actionButtonState == 1)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Highlighted_Normal"];
						else if (actionButtonState == -1)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Highlighted_Hover"];
						else if (actionButtonState == 2)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Highlighted_Clicked"];
					}
					else
					{
						if (actionButtonState == 1)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Normal"];
						else if (actionButtonState == -1)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Hover"];
						else if (actionButtonState == 2)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Clicked"];
					}
				}
				else
				{
					if (isHighlighted)
					{
						if (actionButtonState == 1)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Highlighted_Normal"];
						else if (actionButtonState == -1)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Highlighted_Hover_Inactive"];
						else if (actionButtonState == 2)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Highlighted_Clicked_Inactive"];
					}
					else
					{
						if (actionButtonState == 1)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Normal_Inactive"];
						else if (actionButtonState == -1)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Hover_Inactive"];
						else if (actionButtonState == 2)
							cog = [NSImage imageNamed:@"XBNewSourceList_AddButton_Clicked_Inactive"];
					}
				}
				
				[cog drawInRect:cogRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
			}
		}
		
		//Draw Text
		cellFrame.size.width -= offset + 3;
		cellFrame.origin.x += offset;
		if (actionButtonState != 0)
			cellFrame.size.width -= actionButtonDiameter + 2*actionButtonMargin - 2.0;
		
		if (cellFrame.size.width > 1.0 && cellFrame.size.height > 1.0)
			[super drawWithFrame:cellFrame inView:controlView];
		
		return;
	}
	 */
	
	
	//Set up geometry
	NSRect labelRect = cellFrame;
	labelRect.size.height -= 2;
	labelRect.origin.y += 1;
	if (actionButtonState != 0)
		labelRect.size.width -= actionButtonDiameter + 2*actionButtonMargin - 2.0;
	
	[[[self class] baseColorForLabel:label] set];
	
	
	//Draw Label Color
	/*
	if (![label isEqual:XBSourceListLabelClear])
	{
		[bp fill];
		
		NSGradient *grad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.46] endingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.0]];
		[grad drawInBezierPath:bp angle:90];
	}
	 */
	
	
	//Draw Highlight
	if (isHighlighted && ![label isEqual:XBSourceListLabelClear])
	{
		/*
		NSRect highlightRect = labelRect;
		highlightRect = NSInsetRect(highlightRect, 2, 2);
		
		bp = [NSBezierPath bezierPathWithRoundedRect:highlightRect xRadius:highlightRect.size.height/2.0 yRadius:highlightRect.size.height/2.0];
		[[NSColor whiteColor] set];
		[bp fill];
		
		NSGradient *grad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.31 green:0.53 blue:0.81 alpha:1.00] endingColor:[NSColor colorWithCalibratedRed:0.15 green:0.39 blue:0.71 alpha:1.00]];
		if ([[controlView window] firstResponder] != controlView || ![[controlView window] isKeyWindow])
			grad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.61 green:0.67 blue:0.80 alpha:1.00] endingColor:[NSColor colorWithCalibratedRed:0.47 green:0.54 blue:0.69 alpha:1.00]];
		if (![[controlView window] isMainWindow])
			grad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.69 green:0.69 blue:0.69 alpha:1.00] endingColor:[NSColor colorWithCalibratedRed:0.57 green:0.57 blue:0.57 alpha:1.00]];
		
		 
		if ([tableView isDraggingImage] == NO)
		*/
		{
			//[NSGraphicsContext saveGraphicsState];
			//[bp setClip];
			[tableView highlightSelectionInClipRect:cellFrame];
			//[NSGraphicsContext restoreGraphicsState];
		}
		/*
		else
		{
			[grad drawInBezierPath:bp angle:90];
		}
		 */
	}
	
	float offset = 7;
	
	
	//Draw Image
	if (hasCloseButton)
	{
		NSString *closeButtonString = [NSString stringWithFormat:@"%C", 0x00D7];
		NSMutableDictionary *closeButtonAttrs = [[NSMutableDictionary alloc] init];
		[closeButtonAttrs setValue:[NSFont fontWithName:@"Menlo" size:14] forKey:NSFontAttributeName];
		
		NSShadow *closeButtonShadow = [[NSShadow alloc] init];
		[closeButtonShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[closeButtonShadow setShadowBlurRadius:0.0];
		
		if (isHighlighted)
		{
			[closeButtonAttrs setValue:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.000] forKey:NSForegroundColorAttributeName];
			[closeButtonShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.25]];
		}
		else
		{
			[closeButtonAttrs setValue:[NSColor colorWithCalibratedRed:0.467 green:0.520 blue:0.584 alpha:1.000] forKey:NSForegroundColorAttributeName];
			[closeButtonShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.85]];
		}
		
		[closeButtonAttrs setValue:closeButtonShadow forKey:NSShadowAttributeName];
		
		NSSize closeButtonSize = [closeButtonString sizeWithAttributes:closeButtonAttrs];
		
		[closeButtonString drawAtPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y - 1) withAttributes:closeButtonAttrs];
		
		closeButtonSize.width += 3.0;
		cellFrame.size.width -= closeButtonSize.width;
		cellFrame.origin.x += closeButtonSize.width;
	}
	
	
	if (image)
	{
		NSPoint point = cellFrame.origin;
		point.x += 2;
		point.y += 2;

		NSImage *img = (isHighlighted ? alternateImage : image);
		if (!alternateImage)
			img = image;
		
		//BOOL oldFlipped = [image isFlipped];
		[img setFlipped:NO];
		//[image drawInRect: fromRect: operation: fraction:];// :point operation:NSCompositeSourceOver];// fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[img drawInRect:NSMakeRect(point.x, point.y, 16, 16) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
		//[image setFlipped:oldFlipped];
		
		offset += 14;
	}
	
	
	//Draw Action Button
	
	hasCloseButton = NO;
	actionButtonState = 1;
	if (hasCloseButton) //(actionButtonState != 0)
	{
		//Draw circle
		NSSize circleSize = NSMakeSize(8, 9);
		NSRect circleRect = NSMakeRect(cellFrame.origin.x + cellFrame.size.width - actionButtonMargin - circleSize.width + 2.0, cellFrame.origin.y + actionButtonMargin, circleSize.width, circleSize.height);
		
		//Draw Cog
		NSRect cogRect = circleRect; //NSInsetRect(circleRect, 2.0, 2.0);
		NSImage *cog = nil;
		
		if ([[controlView window] isMainWindow] || [[[controlView window] contentView] isInFullScreenMode])
		{
			if (isHighlighted)
			{
				if (actionButtonState == 1)
					cog = [NSImage imageNamed:@"sourcelist_close_active_normal_selected"];
				else if (actionButtonState == -1)
					cog = [NSImage imageNamed:@"sourcelist_close_active_hover_selected"];
				else if (actionButtonState == 2)
					cog = [NSImage imageNamed:@"sourcelist_close_active_clicked_selected"];
			}
			else
			{
				if (actionButtonState == 1)
					cog = [NSImage imageNamed:@"sourcelist_close_active_normal"];
				else if (actionButtonState == -1)
					cog = [NSImage imageNamed:@"sourcelist_close_active_hover"];
				else if (actionButtonState == 2)
					cog = [NSImage imageNamed:@"sourcelist_close_active_clicked"];
			}
		}
		else
		{
			if (isHighlighted)
			{
				if (actionButtonState == 1)
					cog = [NSImage imageNamed:@"sourcelist_close_inactive_normal_selected"];
				else if (actionButtonState == -1)
					cog = [NSImage imageNamed:@"sourcelist_close_inactive_hover_selected"];
				else if (actionButtonState == 2)
					cog = [NSImage imageNamed:@"sourcelist_close_inactive_clicked_selected"];
			}
			else
			{
				if (actionButtonState == 1)
					cog = [NSImage imageNamed:@"sourcelist_close_inactive_normal"];
				else if (actionButtonState == -1)
					cog = [NSImage imageNamed:@"sourcelist_close_inactive_hover"];
				else if (actionButtonState == 2)
					cog = [NSImage imageNamed:@"sourcelist_close_inactive_clicked"];
			}
		}

		[cog setFlipped:YES];
		[cog drawInRect:cogRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	
	
	//Draw Text
	//offset -= 10;
	cellFrame.size.width -= 4;
	cellFrame.origin.x += offset;
	if (actionButtonState != 0)
		cellFrame.size.width -= actionButtonDiameter + 2*actionButtonMargin - 2.0;
	
	cellFrame.origin.y += 3;
	
	if (cellFrame.size.width > 1.0 && cellFrame.size.height > 1.0)
	{
		NSFont *oldFont = [self font];
		if (isHighlighted)
		{
			NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:oldFont toHaveTrait:NSBoldFontMask];
			[self setFont:newFont];
		}
		
		[super drawWithFrame:cellFrame inView:controlView];
		
		if (isHighlighted)
			[self setFont:oldFont];
	}
}
+ (NSColor *)baseColorForLabel:(XBSourceListLabel *)l
{
	if ([l isEqual:XBSourceListLabelNA])
		return nil;
	else if ([l isEqual:XBSourceListLabelClear])
		return [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];
	else if ([l isEqual:XBSourceListLabelRed])
		return [NSColor colorWithCalibratedRed:1.00 green:0.47 blue:0.44 alpha:1.00];
	else if ([l isEqual:XBSourceListLabelOrange])
		return [NSColor colorWithCalibratedRed:0.98 green:0.72 blue:0.35 alpha:1.00];
	else if ([l isEqual:XBSourceListLabelYellow])
		return [NSColor colorWithCalibratedRed:0.95 green:0.88 blue:0.37 alpha:1.00];
	else if ([l isEqual:XBSourceListLabelGreen])
		return [NSColor colorWithCalibratedRed:0.75 green:0.87 blue:0.37 alpha:1.00];
	else if ([l isEqual:XBSourceListLabelBlue])
		return [NSColor colorWithCalibratedRed:0.42 green:0.71 blue:1.00 alpha:1.00];
	else if ([l isEqual:XBSourceListLabelPurple])
		return [NSColor colorWithCalibratedRed:0.80 green:0.63 blue:0.87 alpha:1.00];
	else if ([l isEqual:XBSourceListLabelGray])
		return [NSColor colorWithCalibratedRed:0.72 green:0.72 blue:0.72 alpha:1.00];
	return nil;
}

@end
