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
	
	/*
	if ([self hasKey:@"lightsplit"])
	{		
		NSManagedObjectContext *ctx = [self managedObjectContext];
		
		NSEntityDescription *lightsplitEntity = [NSEntityDescription entityForName:@"DocRecordLightSplit" inManagedObjectContext:ctx];
		NSManagedObject *lightsplit = [[NSManagedObject alloc] initWithEntity:lightsplitEntity insertIntoManagedObjectContext:ctx];
		
		[lightsplit setValue:[NSNumber numberWithShort:[self priorityval]] forKey:@"priority"];
		
		[self setValue:lightsplit forKey:@"lightsplit"];
		
		NSEntityDescription *heavysplitEntity = [NSEntityDescription entityForName:@"DocRecordHeavySplit" inManagedObjectContext:ctx];
		NSManagedObject *heavysplit = [[NSManagedObject alloc] initWithEntity:heavysplitEntity insertIntoManagedObjectContext:ctx];
		[self setValue:heavysplit forKey:@"heavysplit"];
	}
	*/
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

- (BOOL)isKindOfEntityNamed:(NSString *)entityName
{
	NSManagedObjectContext *ctx = [self managedObjectContext];
	return [[self entity] isKindOfEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:ctx]];
}
- (BOOL)hasKey:(NSString *)key
{
	NSDictionary *properties = [[self entity] propertiesByName];
	return ([properties objectForKey:key] != nil);
}
- (id)valueForSoftKey:(NSString *)key
{
	if (![self hasKey:key])
		return nil;
	
	return [self valueForKey:key];
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
	
	else if([entityName isEqual:@"ObjCNotification"])
		return CHSymbolButtonNotification;
	
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


#pragma mark Jumping through Idiotic Hoops

//Core Data has provided the perfect storm for us. Single table inheritence, underpowered NSFetchRequest, no cursors, no overriding valueForKey:
//The end result is some very ugly code. You have been warned

/*
#define HOOPS(nom, capNom) - (id) nom { return [[self valueForKey:@"lightsplit"] valueForKey:@#nom ]; } \
- (void) set##capNom :(id)n { [[self valueForKey:@"lightsplit"] setValue:n forKey:@#nom ]; }

HOOPS(name, Name)
HOOPS(priority, Priority)
HOOPS(documentPath, DocumentPath)

#define HEAVYHOOPS(nom, capNom) - (id) nom { return [[self valueForKey:@"heavysplit"] valueForKey:@#nom ]; } \
- (void) set##capNom :(id)n { [[self valueForKey:@"heavysplit"] setValue:n forKey:@#nom ]; }

HEAVYHOOPS(availability, Availability)
HEAVYHOOPS(declaration, Declaration)
HEAVYHOOPS(declared_in_header, Declared_in_header)

HEAVYHOOPS(discussion, Discussion)
HEAVYHOOPS(example, Example)
HEAVYHOOPS(overview, Overview)

HEAVYHOOPS(signature, Signature)
HEAVYHOOPS(specialConsiderations, SpecialConsiderations)
*/
@end
