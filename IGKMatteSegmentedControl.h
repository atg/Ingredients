//
//  IGKMatteSegmentedControl.h
//  Ingredients
//
//  Created by Alex Gordon on 27/02/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IGKMatteSegmentedControl : NSSegmentedControl {

}

+ (NSBezierPath *)roundedBezierInRect:(NSRect)rect radius:(float)radius hasLeft:(BOOL)hasLeft hasRight:(BOOL)hasRight;

- (void)drawSegmentDivider:(NSUInteger)segmentIndex isSelected:(BOOL)isSelected runningX:(float)runningX;
- (float)drawSegmentSegment:(NSUInteger)segmentIndex isSelected:(BOOL)isSelected runningX:(float)runningX;

@end
