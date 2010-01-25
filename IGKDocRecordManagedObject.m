//
//  IGKDocRecordManagedObject.m
//  Ingredients
//
//  Created by Alex Gordon on 25/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKDocRecordManagedObject.h"


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
	
	//Get from CHSymbolButtonImage
	
	return nil;
}

@end
