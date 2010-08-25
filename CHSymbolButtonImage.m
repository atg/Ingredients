//
//  CHSymbolButtonImage.m
//  Chocolat
//
//  Created by Alex Gordon on 11/09/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import "CHSymbolButtonImage.h"


@implementation CHSymbolButtonImage

static NSMutableDictionary *sharedSymbolButtonImageCache = nil;

+ (NSArray *)symbolImageWithTypeString:(NSString *)typeString drawBorder:(BOOL)drawBorder
{
	CHSymbolButtonImageMask m = 0;
	
	if (!drawBorder)
		m |= CHSymbolButtonDontDrawBorder;
	
	if ([typeString isEqual:@"f"])
		m |= CHSymbolButtonFunction;
	
	else if ([typeString isEqual:@"@"])
		m |= CHSymbolButtonObjcClass | CHSymbolButtonObjcInterface;
	
	else if ([typeString isEqual:@"FF"])
		m |= CHSymbolButtonFunctionContainer;
	
	else if ([typeString isEqual:@"@p"])
		m |= CHSymbolButtonObjcProtocol | CHSymbolButtonObjcInterface;
	
	else if ([typeString isEqual:@"@+"])
		m |= CHSymbolButtonObjcCategory | CHSymbolButtonObjcInterface;
	
	else if ([typeString isEqual:@"@ip"])
		m |= CHSymbolButtonObjcClass | CHSymbolButtonObjcImplementation;
	
	else if ([typeString isEqual:@"@pr"])
		m |= CHSymbolButtonObjcProperty;
	
	else if ([typeString isEqual:@"@m"])
		m |= CHSymbolButtonObjcMethod;
	
	else if ([typeString isEqual:@"@@m"])
		m |= CHSymbolButtonObjcMethod | CHSymbolButtonStaticScope;
	
	else if ([typeString isEqual:@"iv"])
		m |= CHSymbolButtonVariable | CHSymbolButtonInstanceScope;
	
	else if ([typeString isEqual:@"v"])
		m |= CHSymbolButtonVariable;
	
	else if ([typeString isEqual:@"ev"])
		m |= CHSymbolButtonVariable;
	
	if (m)
		return [self symbolImageWithMask:m];
	
	return nil;
}
+ (NSArray *)symbolImageWithMask:(CHSymbolButtonImageMask)mask
{
	@synchronized(sharedSymbolButtonImageCache)
	{
		if (sharedSymbolButtonImageCache == nil)
			sharedSymbolButtonImageCache = [[NSMutableDictionary alloc] initWithCapacity:20];
		
		NSArray *cachedImage = [sharedSymbolButtonImageCache objectForKey:[NSNumber numberWithUnsignedLongLong:mask]];
		if (cachedImage)
			return cachedImage;
		
		
		NSString *str = @"";
		CGFloat offset = 0.0;
		BOOL bold = NO;
		
		if (mask & CHSymbolButtonMacro)
		{
			str = @"#";
			offset = 0.0;
		}
		
		if (mask & CHSymbolButtonTypedef)
		{
			offset = 30;
			if (mask & CHSymbolButtonStruct)
				str = @"S";
			else if (mask & CHSymbolButtonUnion)
				str = @"U";
			else if (mask & CHSymbolButtonEnum)
				str = @"E";
			else if (mask & CHSymbolButtonCppClass)
				str = @"C";
			else
				str = @"T";
		}
		
		else if (mask & CHSymbolButtonFunction)
		{
			offset = 209.0;
			str = [NSString stringWithFormat:@"%C", 0x0192];
		}
		else if (mask & CHSymbolButtonFunctionContainer)
		{
			offset = 209.0;
			str = @"F";
		}
		else if (mask & CHSymbolButtonObjcMethod)
		{
			if (mask & CHSymbolButtonStaticScope)
				offset = 231.0;
			else
				offset = 209.0;
			str = @"M";
		}
		else if (mask & CHSymbolButtonObjcProperty)
		{
			offset = 170.0 + (209.0 - 170.0) * 2.0 / 4.0;
			str = @"P";
		}
		
		else if (mask & CHSymbolButtonStruct)
		{
			offset = 330;
			str = @"S";
		}
		else if ((mask & CHSymbolButtonUnion) || (mask & CHSymbolButtonEnum))
		{
			offset = 60;
			if (mask & CHSymbolButtonUnion)
				str = @"U";
			else //if (mask & CHSymbolButtonEnum)
				str = @"E";
		}
		else if (mask & CHSymbolButtonUnion)
		{
			offset = 330;
			str = @"C";
		}
		
		else if ((mask & CHSymbolButtonObjcClass) || (mask & CHSymbolButtonCppClass))
		{
			offset = 252.0;
			str = @"C";
		}
		else if (mask & CHSymbolButtonObjcBindingsListing)
		{
			offset = 252.0;
			str = @"B";
		}
		else if (mask & CHSymbolButtonObjcProtocol)
		{
			offset = 252.0;
			str = @"P";
		}
		else if (mask & CHSymbolButtonObjcCategory)
		{
			offset = 252.0;
			str = @"+";
			bold = YES;
		}
		
		else if (mask & CHSymbolButtonVariable)
		{
			str = @"v";
			if (mask & CHSymbolButtonInstanceScope)
				offset = 170.0;//180.0;
			else
				offset = 120.0;
		}
		else if (mask & CHSymbolButtonNotification)
		{
			str = @"N";
			offset = 120.0;
		}
		
		if (![str length])
			return nil;
		
		NSArray *imageTuple = [NSArray arrayWithObjects:
							    [self symbolImageWithString:str offset:offset bold:bold isWhite:NO drawBorder:(mask & CHSymbolButtonDontDrawBorder) == 0],
								[self symbolImageWithString:str offset:offset bold:bold isWhite:YES drawBorder:(mask & CHSymbolButtonDontDrawBorder) == 0],
							    nil];
		[sharedSymbolButtonImageCache setObject:imageTuple forKey:[NSNumber numberWithUnsignedLongLong:mask]];
		return imageTuple;
	}
}

+ (NSImage *)symbolImageWithString:(NSString *)str offset:(CGFloat)offset bold:(BOOL)isBold isWhite:(BOOL)isWhite drawBorder:(BOOL)drawBorder
{
	if (isWhite)
		isBold = YES;
	
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(16, 17)];
	[image lockFocus];
	
	
	float radius = 3;
	NSRect rect = NSMakeRect(0, 1, 16, 16);
	offset -= 209.0;
	offset /= 360.0;	
	
	NSBezierPath *bp = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
	NSGradient *g;
	
	float backgroundFactor = 0.9;
	
	
	if (isWhite == NO)
	{
		g = [[NSGradient alloc] initWithStartingColor:[self rotateColor:[NSColor colorWithCalibratedRed:0.644 green:0.716 blue:0.834 alpha:1.000] byOffset:offset]
												  endingColor:[self rotateColor:[NSColor colorWithCalibratedRed:0.779 green:0.846 blue:0.909 alpha:1.000] byOffset:offset]];
	
		[g drawInBezierPath:bp angle:90];
	}
	else
	{
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.23] set];
		
		[[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.6 * backgroundFactor] set];
		[[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:radius - 1 yRadius:radius - 1] stroke];
		
		
	}

	
	
	//Inner
	bp = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 1, 1) xRadius:radius - 1 yRadius:radius - 1];
	if (isWhite == NO)
	{
		g = [[NSGradient alloc] initWithStartingColor:[self rotateColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.4] byOffset:offset]
										  endingColor:[self rotateColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.4] byOffset:offset]];
		if (drawBorder)
			[g drawInBezierPath:bp angle:90];
	}
	else
	{
		[[NSColor colorWithCalibratedWhite:0.75 alpha:0.625 * backgroundFactor] set];
		[[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(NSInsetRect(rect, 1.0, 1.0), 0.5, 0.5) xRadius:radius - 1 yRadius:radius - 1] stroke];
	}
	
	//Fill
	bp = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 2, 2) xRadius:radius - 2 yRadius:radius - 2];
	if (isWhite == NO)
	{
		g = [[NSGradient alloc] initWithStartingColor:[self rotateColor:[NSColor colorWithCalibratedRed:0.712 green:0.799 blue:0.905 alpha:1.000] byOffset:offset]
									  endingColor:[self rotateColor:[NSColor colorWithCalibratedRed:0.817 green:0.889 blue:0.953 alpha:1.000] byOffset:offset]];
		
		if (drawBorder)
			[g drawInBezierPath:bp angle:90];
	}
	else
	{
		g = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.25 * backgroundFactor]
										  endingColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.5 * backgroundFactor]];
		
		[g drawInBezierPath:bp angle:90];
	}
	
	
	
	//Text
	NSMutableDictionary *attrs = [[NSMutableDictionary alloc] initWithCapacity:2];
	[attrs setValue:(isBold ? [NSFont boldSystemFontOfSize:11] : [NSFont systemFontOfSize:11]) forKey:NSFontAttributeName];
	
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(0, -1)];
	[shadow setShadowBlurRadius:0.0];
	
	if (isWhite)
	{
		[attrs setValue:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
		[shadow setShadowOffset:NSMakeSize(0, -1)];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
		[shadow setShadowBlurRadius:1.0];
	}
	else
	{
		[attrs setValue:[self rotateColor:[NSColor colorWithCalibratedRed:0.045 green:0.209 blue:0.384 alpha:1.000] byOffset:offset] forKey:NSForegroundColorAttributeName];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.55]];
	}
		
	[attrs setValue:shadow forKey:NSShadowAttributeName];
	
	BOOL isUppercase = [str length] > 0 && [str characterAtIndex:0] >= 'A' && [str characterAtIndex:0] <= 'Z';
	
	NSSize size = [str sizeWithAttributes:attrs];
	NSPoint p = NSMakePoint(rect.origin.x + rect.size.width/2.0 - size.width/2.0 + 0.5, rect.origin.y + rect.size.height/2.0 - size.height/2.0 + 1 + (isUppercase ? -1 : 0));
	
	[str drawAtPoint:p withAttributes:attrs];
	
	
	
	[image unlockFocus];
	return image;
}

+ (NSColor *)rotateColor:(NSColor *)c byOffset:(CGFloat)offset
{	
	return [NSColor colorWithCalibratedHue:fmod([c hueComponent] + offset, 1.0) saturation:[c saturationComponent] brightness:[c brightnessComponent] alpha:[c alphaComponent]];
}
+ (NSColor *)rotateColor:(NSColor *)c toOffset:(CGFloat)offset
{
	return [NSColor colorWithCalibratedHue:offset saturation:[c saturationComponent] brightness:[c brightnessComponent] alpha:[c alphaComponent]];
}

@end
