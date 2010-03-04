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
- (CHSymbolButtonImageMask)iconMask;

@end


@implementation IGKDocRecordManagedObject

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	[self setValue:[NSNumber numberWithShort:[self priorityval]] forKey:@"priority"];
}
- (CHRecordPriority)priorityval
{
	NSString *entityName = [[self entity] name];
	
	if([entityName isEqual:@"ObjCMethod"])
		return CHPriorityMethod;
	
	else if([entityName isEqual:@"ObjCClass"])
		return CHPriorityClass;
	
	else if([entityName isEqual:@"ObjCProtocol"])
		return CHPriorityProtocol;
	
	else if([entityName isEqual:@"ObjCCategory"])
		return CHPriorityCategory;
	
	else if([entityName isEqual:@"CTypedef"])
		return CHPriorityType;
	
	else if([entityName isEqual:@"CEnum"])
		return CHPriorityType;
	
	else if([entityName isEqual:@"CStruct"])
		return CHPriorityType;
	
	else if([entityName isEqual:@"CFunction"])
		return CHPriorityFunction;
	
	else if([entityName isEqual:@"CMacro"])
		return CHPriorityFunction;
	
	else if([entityName isEqual:@"CppClassStruct"])
		return CHPriorityClass;
	
	else if([entityName isEqual:@"CppMethod"])
		return CHPriorityMethod;
	
	else if([entityName isEqual:@"CUnion"])
		return CHPriorityType;
	
	return CHPriorityOther;
}

- (NSString *)xcontainername
{
	return [[self xcontainer] valueForKey:@"name"];
}
- (IGKDocRecordManagedObject *)xcontainer
{
	NSDictionary *relationships = [[self entity] relationshipsByName];
	if ([relationships objectForKey:@"container"])
		return [self valueForKey:@"container"];
	
	return [self valueForKey:@"misccontainer"];
}

- (NSImage *)normalIcon
{
	return [self iconForSelectedState:NO];
}
- (NSImage *)selectedIcon
{
	return [self iconForSelectedState:YES];
}

- (CHSymbolButtonImageMask)iconMask
{
	//FIXME: Maybe it would be better to use an NSDictionary -> NSNumber here instead
	
	NSString *entityName = [[self entity] name];

	if([entityName isEqual:@"ObjCClass"])
		return CHSymbolButtonObjcClass;
	
	else if([entityName isEqual:@"ObjCCategory"])
		return CHSymbolButtonObjcCategory;
	
	else if([entityName isEqual:@"ObjCProtocol"])
		return CHSymbolButtonObjcProtocol;
	
	else if([entityName isEqual:@"ObjCMethod"])
	{
		if ([[self valueForKey:@"isInstanceMethod"] boolValue])
			return CHSymbolButtonObjcMethod;
		else
			return CHSymbolButtonObjcMethod | CHSymbolButtonStaticScope;
	}
	
	else if([entityName isEqual:@"CTypedef"])
		return CHSymbolButtonTypedef;
	
	else if([entityName isEqual:@"CEnum"])
		return CHSymbolButtonEnum;
	
	else if([entityName isEqual:@"CUnion"])
		return CHSymbolButtonUnion;
	
	else if([entityName isEqual:@"CStruct"])
		return CHSymbolButtonStruct;
	
	else if([entityName isEqual:@"CFunction"])
		return CHSymbolButtonFunction;
	
	else if([entityName isEqual:@"CGlobal"] || [entityName isEqual:@"CConstant"])
		return CHSymbolButtonVariable | CHSymbolButtonGlobalScope;
	
	else if([entityName isEqual:@"CMacro"])
		return CHSymbolButtonMacro;
	
	else if([entityName isEqual:@"CppClassStruct"])
		return CHSymbolButtonCppClass;
	
	else if([entityName isEqual:@"CppMethod"])
		return CHSymbolButtonFunction | CHSymbolButtonInstanceScope;
	
	else if([entityName isEqual:@"CppNamespace"])
		return CHSymbolButtonCppNamespace;
	
	else if([entityName isEqual:@"ObjCBindingsListing"])
		return CHSymbolButtonObjcBindingsListing;
	
	return 0;
}
- (NSImage *)iconForSelectedState:(BOOL)isSelected
{	
	NSInteger index = isSelected ? 1 : 0;
	
	CHSymbolButtonImageMask mask = [self iconMask];
	
	if (!mask)
		return nil;
	
	return [[CHSymbolButtonImage symbolImageWithMask:mask] objectAtIndex:index];
}

@end
