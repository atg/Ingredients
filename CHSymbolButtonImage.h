//
//  CHSymbolButtonImage.h
//  Chocolat
//
//  Created by Alex Gordon on 11/09/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import <Cocoa/Cocoa.h>

typedef enum _CHSymbolButtonImageType
{
	CHSymbolButtonTypedef = 1<<1,
	
	CHSymbolButtonStruct = 1<<2,
	CHSymbolButtonUnion = 1<<3,
	CHSymbolButtonEnum = 1<<4,
	CHSymbolButtonCppClass = 1<<5,
	CHSymbolButtonCppNamespace = 1<<6,
	
	CHSymbolButtonObjcInterface = 1<<7,
	CHSymbolButtonObjcImplementation = 1<<8,
	
	CHSymbolButtonObjcClass = 1<<16,
	CHSymbolButtonObjcProtocol = 1<<17,
	CHSymbolButtonObjcCategory = 1<<18, //For example: ObjcCategory | ObjcInterface
	CHSymbolButtonFunctionContainer = 1<<19,
	
	CHSymbolButtonVariable = 1<<20,
	CHSymbolButtonObjcMethod = 1<<21,
	CHSymbolButtonObjcProperty = 1<<22,
	CHSymbolButtonFunction = 1<<23,
	
	CHSymbolButtonLocalScope = 1<<25,
	CHSymbolButtonInstanceScope = 1<<26,
	CHSymbolButtonStaticScope = 1<<27,
	CHSymbolButtonGlobalScope = 1<<28,

	CHSymbolButtonMacro = 1<<30,
	CHSymbolButtonDefine = 1<<31,
	
	CHSymbolButtonDontDrawBorder = 1<<9,
	CHSymbolButtonObjcBindingsListing = 1<<10,
	CHSymbolButtonNotification = 1<<11,
	
} CHSymbolButtonImageType; 

typedef uint64_t CHSymbolButtonImageMask;

@interface CHSymbolButtonImage : NSObject {
	
}

+ (NSArray *)symbolImageWithTypeString:(NSString *)typeString drawBorder:(BOOL)drawBorder;
+ (NSArray *)symbolImageWithMask:(CHSymbolButtonImageMask)mask;
+ (NSImage *)symbolImageWithString:(NSString *)str offset:(CGFloat)offset bold:(BOOL)isBold isWhite:(BOOL)isWhite drawBorder:(BOOL)drawBorder;

+ (NSColor *)rotateColor:(NSColor *)c byOffset:(CGFloat)offset;
+ (NSColor *)rotateColor:(NSColor *)c toOffset:(CGFloat)offset;

@end
