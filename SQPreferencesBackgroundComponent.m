//
//  SQPreferencesBackgroundComponent.m
//  Squish
//
//  Created by Alex Gordon on 09/04/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import "SQPreferencesBackgroundComponent.h"


@implementation SQPreferencesBackgroundComponent

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    rect = [self bounds];
	
	//Bottom line
	NSRect line = rect;
	line.size.height = 1;
	[[NSColor colorWithCalibratedRed:0.94 green:0.94 blue:0.94 alpha:1.00] set];
	NSRectFill(line);
	
	line.origin.y += 1;
	[[NSColor colorWithCalibratedRed:0.80 green:0.80 blue:0.80 alpha:1.00] set];
	NSRectFill(line);
	
	line.origin.y += 1;
	line.size.height = rect.size.height - 4.0;
	[[NSColor colorWithCalibratedRed:0.87 green:0.87 blue:0.87 alpha:1.00] set];
	NSRectFill(line);
	
	line.origin.y += line.size.height;
	line.size.height = 1;
	[[NSColor colorWithCalibratedRed:0.91 green:0.91 blue:0.91 alpha:1.00] set];
	NSRectFill(line);
	
	line.origin.y += 1;
	[[NSColor colorWithCalibratedRed:0.81 green:0.81 blue:0.81 alpha:1.00] set];
	NSRectFill(line);
}

@end
