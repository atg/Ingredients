//
//  IGKDocRecordManagedObject.m
//  Ingredients
//
//  Created by Alex Gordon on 25/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKDocRecordManagedObject.h"
#import "CHSymbolButtonImage.h"

@interface IGKDocRecordManagedObject ()

- (NSImage *)iconForSelectedState:(BOOL)isSelected;

@end


@implementation IGKDocRecordManagedObject

- (NSImage *)normalIcon
{
	return [self iconForSelectedState:NO];
}
- (NSImage *)selectedIcon
{
	return [self iconForSelectedState:YES];
}
- (NSImage *)iconForSelectedState:(BOOL)isSelected
{
	NSString *entityName = [[self entity] name];
	
	NSInteger index = isSelected ? 1 : 0;
	
	
	if([entityName isEqual:@"ObjCClass"])
		return [[CHSymbolButtonImage symbolImageWithMask:CHSymbolButtonObjcClass] objectAtIndex:index];
	else if([entityName isEqual:@"ObjCCategory"])
		return [[CHSymbolButtonImage symbolImageWithMask:CHSymbolButtonObjcCategory] objectAtIndex:index];
	else if([entityName isEqual:@"ObjCProtocol"])
		return [[CHSymbolButtonImage symbolImageWithMask:CHSymbolButtonObjcProtocol] objectAtIndex:index];
	else if([entityName isEqual:@"ObjCMethod"])
		return [[CHSymbolButtonImage symbolImageWithMask:CHSymbolButtonObjcMethod] objectAtIndex:index];
	
	
	return nil;
}

@end
