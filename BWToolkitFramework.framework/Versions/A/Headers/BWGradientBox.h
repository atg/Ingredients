//
//  BWGradientBox.h
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com)
//  All code is provided under the New BSD license.
//

#import <Cocoa/Cocoa.h>

@interface BWGradientBox : NSView {

	NSColor *fillStartingColor, *fillEndingColor, *fillColor;

	NSColor *topBorderColor, *rightBorderColor, *bottomBorderColor, *leftBorderColor;

	float topInsetAlpha, rightInsetAlpha, bottomInsetAlpha, leftInsetAlpha;
	BOOL hasTopBorder, hasRightBorder, hasBottomBorder, hasLeftBorder;
	BOOL hasGradient, isVertical;

}

@property (nonatomic, retain) NSColor *fillStartingColor, *fillEndingColor, *fillColor;
@property (nonatomic, retain) NSColor *topBorderColor, *rightBorderColor, *bottomBorderColor, *leftBorderColor;
@property float topInsetAlpha, rightInsetAlpha, bottomInsetAlpha, leftInsetAlpha;
@property BOOL hasTopBorder, hasRightBorder, hasBottomBorder, hasLeftBorder;
@property BOOL hasGradient, isVertical;

@end
