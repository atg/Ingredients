//
//  IGKTableOfContentsView.m
//  Ingredients
//
//  Created by Alex Gordon on 06/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKTableOfContentsView.h"

const float ToCSideEdgePadding = 12.0;
const float ToCIconTitleBetweenPadding = 13.0;

const float ToCRowBetweenMargin = 1.0;
const float ToCRowSideMargin = 4.0;
const float ToCRowTopMargin = 5.0;
const float ToCRowBottomMargin = 4.0;

//The old table view had a row height of 24 pixels
const float ToCRowHeight = 31.0;


@interface IGKTableOfContentsView ()

- (NSDictionary *)titleAttributesForSelected:(BOOL)isSelected;
- (BOOL)isActive;

- (void)mouseEvent:(NSEvent *)event isDrag:(BOOL)isDrag;

@end


@implementation IGKTableOfContentsView

@synthesize delegate;
@synthesize selectedRowIndexes;

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		selectedRowIndexes = [[NSMutableIndexSet alloc] init];
		lastDraggedRow = -1;
	}
	
	return self;
}

- (void)reloadData
{
	[self setNeedsDisplay:YES];
}

- (NSDictionary *)titleAttributesForSelected:(BOOL)isSelected
{
	NSMutableDictionary *attrs = [[NSMutableDictionary alloc] init];
	
	
	//Font
	NSFont *font = isSelected ? [NSFont boldSystemFontOfSize:13] : [NSFont boldSystemFontOfSize:11.5];
	[attrs setValue:font forKey:NSFontAttributeName];
	
	
	//Color
	NSColor *color = [NSColor colorWithCalibratedHue:0.59 saturation:0.36 brightness:0.44 alpha:1.00];//[NSColor colorWithCalibratedRed:0.329 green:0.384 blue:0.451 alpha:1.000];
	if (isSelected)
		color = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
	else if (![self isActive])
		color = [NSColor colorWithCalibratedWhite:0.448 alpha:1.0];
	
	[attrs setValue:color forKey:NSForegroundColorAttributeName];
	
	
	//Shadow
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow setShadowBlurRadius:0.0];
	if (isSelected)
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.25]];
	else
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.3]];
	
	[attrs setValue:shadow forKey:NSShadowAttributeName];
	
	
	//Paragraph style
	NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
	[para setLineBreakMode:NSLineBreakByTruncatingTail];
	
	[attrs setValue:para forKey:NSParagraphStyleAttributeName];
	
	
	return attrs;
}

- (void)drawRect:(NSRect)dirtyRect
{
	//*** Parameters ***
	
	//The color of the line at the very top of the view
	NSColor *topBorderColor = [NSColor colorWithCalibratedRed:0.65 green:0.65 blue:0.65 alpha:1.00];
	
	//The view's background color
	NSColor *normalBackgroundColor = [NSColor colorWithCalibratedRed:0.838 green:0.864 blue:0.898 alpha:1.000];//[NSColor colorWithCalibratedRed:0.839 green:0.867 blue:0.898 alpha:1.000];
	NSColor *inactiveBackgroundColor = [NSColor colorWithCalibratedRed:0.912 green:0.912 blue:0.912 alpha:1.000];
		
	//The color of the view's vertical pinstripes
	NSColor *stripeColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.1];
	
	//The width of each pinstripe
	const float stripeWidth = 10.0;
	
	//The color of the line at the very top of the view
	NSColor *topBorderHighlightColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.27];
	NSColor *topHighlightGradientColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.6];
	const float topHighlightGradientHeight = 30.0;//33.0;
	
	//The top color of the selection gradient
	NSColor *selectionGradientStartColor = [NSColor colorWithCalibratedRed:0.686 green:0.729 blue:0.835 alpha:1.000];
	NSColor *inactiveSelectionGradientStartColor = [NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.000];
	
	//The bottom color of the selection gradient
	NSColor *selectionGradientEndColor = [NSColor colorWithCalibratedRed:0.537 green:0.600 blue:0.733 alpha:1.000];
	NSColor *inactiveSelectionGradientEndColor = [NSColor colorWithCalibratedRed:0.623 green:0.623 blue:0.623 alpha:1.000];
	
	//The radius of the row selection rect's corners
	const float selectionRectCornerRadius = 4.0;
	
	
	//*** Constants ***
	const NSRect rect = [self bounds];
	BOOL isActive = [self isActive];
		
	//*** Drawing ***
	
	//Draw the background
	if (isActive)
		[normalBackgroundColor set];
	else
		[inactiveBackgroundColor set];
	
	NSRectFillUsingOperation(rect, NSCompositeSourceOver);
	
	
	//Draw the stripes
	int i = 0;
	for (i = 0; i < ceil(rect.size.width / stripeWidth); i++)
	{
		//The stripes are alternating, so we only draw if i is even
		if (i % 2 == 1)
			continue;
		
		//The height of each stripe is the height of the view - 2. One pixel for the border and another pixel for the highlight
		NSRect stripeRect = NSMakeRect(i * stripeWidth, 0.0, stripeWidth, rect.size.height - 1.0);
		
		[stripeColor set];
		//NSRectFillUsingOperation(stripeRect, NSCompositeSourceOver);
	}
	
	
	//Draw the top border
	NSRect topBorderRect = NSMakeRect(0.0, 0.0, rect.size.width, 1.0);
	
	[topBorderColor set];
	NSRectFillUsingOperation(topBorderRect, NSCompositeSourceOver);
	
	
	//Draw the top border highlight
	NSRect topBorderHighlightRect = NSMakeRect(0.0, 1.0, rect.size.width, 1.0);
	
	[topBorderHighlightColor set];
	NSRectFillUsingOperation(topBorderHighlightRect, NSCompositeSourceOver);
	
	
	//Draw the top highlight gradient
	NSGradient *topHighlightGradient = [[NSGradient alloc] initWithStartingColor:topHighlightGradientColor
																	 endingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.001]];
	NSRect topHighlightGradientRect = NSMakeRect(0, 1.0, rect.size.width, topHighlightGradientHeight);
	[topHighlightGradient drawInRect:topHighlightGradientRect angle:90];
	
	
	NSUInteger numberOfRows = [delegate numberOfRowsInTableOfContents];
	
	float runningY = ToCRowTopMargin;
	
	NSDictionary *titleAttributes = [self titleAttributesForSelected:NO];
	NSDictionary *selectedTitleAttributes = [self titleAttributesForSelected:YES];
	
	for (i = 0; i < numberOfRows; i++)
	{
		NSImage *icon = [delegate valueForTableOfContentsColumn:IGKTableOfContentsIconColumn row:i];
		NSString *title = [delegate valueForTableOfContentsColumn:IGKTableOfContentsTitleColumn row:i];
		
		BOOL isSelected = [selectedRowIndexes containsIndex:i];
		
		NSRect rowRect = NSMakeRect(ToCRowSideMargin, runningY, rect.size.width - 2.0 * ToCRowSideMargin, ToCRowHeight);

		if (isSelected)
		{
			//Draw the selection background
			NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:rowRect xRadius:selectionRectCornerRadius yRadius:selectionRectCornerRadius];
			
			NSGradient *selectionGradient = nil;
			
			if (isActive)
			{
				selectionGradient = [[NSGradient alloc] initWithStartingColor:selectionGradientStartColor
																  endingColor:selectionGradientEndColor];
			}
			else
			{
				selectionGradient = [[NSGradient alloc] initWithStartingColor:inactiveSelectionGradientStartColor
																  endingColor:inactiveSelectionGradientEndColor];
			}
			
			[selectionGradient drawInBezierPath:selectionPath angle:90];
		}
		
		//Draw the icon
		NSRect iconRect;
		iconRect.origin = NSMakePoint(ToCSideEdgePadding, runningY + ToCRowHeight / 2.0 - [icon size].height / 2.0);
		iconRect.size = [icon size];
		
		[icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
		
		//Draw the title
		NSDictionary *attrs = (isSelected ? selectedTitleAttributes : titleAttributes);
		
		NSSize titleSize = [title sizeWithAttributes:attrs];
		NSRect titleRect;
		titleRect.origin = NSMakePoint(round(NSMaxX(iconRect) + ToCIconTitleBetweenPadding), round(runningY + floor(rowRect.size.height / 2.0 - titleSize.height / 2.0) - (isSelected ? 1.0 : 0)));
		titleRect.size = NSMakeSize(round(rect.size.width - titleRect.origin.x - ToCSideEdgePadding), round(titleSize.height));
		[title drawInRect:titleRect withAttributes:attrs];
		
		//Work out the Y for the next row
		runningY += ToCRowHeight;
		runningY += ToCRowBetweenMargin;
	}
}

- (BOOL)isFlipped
{
	return YES;
}



#pragma mark Geometry

- (NSUInteger)rowIndexForPoint:(NSPoint)p
{
	p.y - ToCRowTopMargin;
	return floor(p.y / (ToCRowHeight + ToCRowBetweenMargin));
}



#pragma mark Redrawing when the window becomes Active/Inactive

- (void)viewWillMoveToWindow:(NSWindow *)window
{
	if (window)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeKeyNotification object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignKeyNotification object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:window];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
	}
	
	[self setNeedsDisplay:YES];
}
- (void)viewDidMoveToWindow
{
	//NSLog(@"viewDidMoveToWindow %d", [self isActive]);
	[self setNeedsDisplay:YES];
}
- (void)windowDidBecomeMain:(NSNotification *)notif
{
	//NSLog(@"windowDidBecomeMain: %d", [self isActive]);
	[splitView setColor:[NSColor colorWithCalibratedRed:0.591 green:0.626 blue:0.684 alpha:1.000]];
	
	[self setNeedsDisplay:YES];
}
- (void)windowDidResignMain:(NSNotification *)notif
{
	//NSLog(@"windowDidResignMain: %d", [self isActive]);
	[splitView setColor:[NSColor colorWithCalibratedRed:0.647 green:0.647 blue:0.647 alpha:1.000]];
	
	[self setNeedsDisplay:YES];
}
- (BOOL)isActive
{	
	return [[self window] isMainWindow] || ([[self delegate] isInFullscreen] && [[self window] isKeyWindow]);
}


#pragma mark Events

- (void)mouseDown:(NSEvent *)event
{
	[self mouseEvent:event isDrag:NO];
}
- (void)mouseDragged:(NSEvent *)event
{
	[self mouseEvent:event isDrag:YES];
}
- (void)mouseUp:(NSEvent *)event
{
	lastDraggedRow = -1;
}

- (void)mouseEvent:(NSEvent *)event isDrag:(BOOL)isDrag
{
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	
	BOOL commandKeyIsDown = NO;
	if ([event modifierFlags] & NSCommandKeyMask)
		commandKeyIsDown = YES;
	
	BOOL shiftKeyIsDown = NO;
	if ([event modifierFlags] & NSShiftKeyMask)
		shiftKeyIsDown = YES;
	
	NSUInteger index = [self rowIndexForPoint:p];
	
	NSIndexSet *oldSelectedIndexes = [selectedRowIndexes copy];
	
	if (commandKeyIsDown || shiftKeyIsDown)
	{
		if (!isDrag || (isDrag && (lastDraggedRow != index)))
		{
			if ([selectedRowIndexes containsIndex:index])
			{
				//cmd-click on a selected row - remove the index
				[selectedRowIndexes removeIndex:index];
			}
			else
			{
				//cmd-click on a non-selected row - add the index
				[selectedRowIndexes addIndex:index];
			}
		}
	}
	else
	{
		//normal-click on a row - select that row
		
		[selectedRowIndexes removeAllIndexes];
		[selectedRowIndexes addIndex:index];
	}
	
	//Set the lastDraggedRow so we don't alternate between disabling and enabling the same row when cmd dragging 
	//Set this for *both* mouse downs and mouse draggeds
	lastDraggedRow = index;
	
	[self setNeedsDisplay:YES];
	
	if (![oldSelectedIndexes isEqualToIndexSet:selectedRowIndexes])
	{
		if ([delegate respondsToSelector:@selector(tableOfContentsChangedSelection)])
			[delegate tableOfContentsChangedSelection];
	}
}

- (BOOL)hasNoItems
{
	return ([[self delegate] numberOfRowsInTableOfContents] == 0);
}
- (float)heightToFit
{
	NSInteger numberOfRows = [[self delegate] numberOfRowsInTableOfContents];
	NSInteger numberOfRowsOr1 = numberOfRows > 0 ? numberOfRows : 1;
	
	return ToCRowTopMargin +
		(numberOfRowsOr1 - 1) * ToCRowBetweenMargin +
		numberOfRows * ToCRowHeight +
		ToCRowBottomMargin;
}

@end
