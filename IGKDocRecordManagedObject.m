//
//  IGKDocRecordManagedObject.m
//  Ingredients
//
//  Created by Alex Gordon on 25/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKDocRecordManagedObject.h"
#import "IGKDocSetManagedObject.h"
#import "CHSymbolButtonImage.h"

@interface IGKDocRecordManagedObject ()

+ (NSString *)entityNameFromURLComponentExtension:(NSString *)ext;

- (NSImage *)iconForSelectedState:(BOOL)isSelected;
- (CHSymbolButtonImageMask)iconMask;

@end


@implementation IGKDocRecordManagedObject

+ (IGKDocRecordManagedObject *)resolveURL:(NSURL *)url inContext:(NSManagedObjectContext *)ctx tableOfContentsMask:(IGKHTMLDisplayTypeMask *)tocMaskPointer
{
	NSArray *components = [url pathComponents];
	/*
	 ingr-doc:// <docset-family> / <docset-version> / <table-of-contents> / <item-name> . <item-type>
	 ingr-doc:// <docset-family> / <docset-version> / <table-of-contents> / <container-name> . <container-type> / <item-name> . <item-type>
	 */
	
	//There should be at least 4 components
	if ([components count] < 4)
		return nil;

	//Remove an initial "/" component
	if ([[components objectAtIndex:0] isEqual:@"/"])
		components = [components subarrayWithRange:NSMakeRange(1, [components count] - 1)];
	
	components = [[NSArray arrayWithObject:[url host]] arrayByAddingObjectsFromArray:components];
	
	// <docset-family>
	NSString *docsetFamily = [components objectAtIndex:0];
	if ([docsetFamily isEqual:@"mac"])
		docsetFamily = @"macosx";
	else if ([docsetFamily isEqual:@"iphone"])
		docsetFamily = @"iphoneos";
	
	// <docset-version>
	NSString *docsetVersion = [components objectAtIndex:1];
	
	NSFetchRequest *docsetFetch = [[NSFetchRequest alloc] init];
	[docsetFetch setEntity:[NSEntityDescription entityForName:@"Docset" inManagedObjectContext:ctx]];
	[docsetFetch setPredicate:[NSPredicate predicateWithFormat:@"platformFamily == %@ && platformVersion == %@", docsetFamily, docsetVersion]];
		
	NSError *err = nil;
	NSArray *docsets = [ctx executeFetchRequest:docsetFetch error:&err];
		
	if (err || ![docsets count])
		return nil;

	IGKDocSetManagedObject *docset = [docsets objectAtIndex:0];
		
	
	// <table-of-contents>
	if (tocMaskPointer)
	{
		NSString *tableOfContents = [components objectAtIndex:2];
		NSArray *tableOfContentsItems = [tableOfContents componentsSeparatedByString:@"."];
		IGKHTMLDisplayTypeMask tocMask = IGKHTMLDisplayType_None;
		
		for (NSString *n in tableOfContentsItems)
		{
			if ([n isEqual:@"all"])
				tocMask |= IGKHTMLDisplayType_All;
			else if ([n isEqual:@"overview"])
				tocMask |= IGKHTMLDisplayType_Overview;
			else if ([n isEqual:@"tasks"])
				tocMask |= IGKHTMLDisplayType_Tasks;
			else if ([n isEqual:@"properties"])
				tocMask |= IGKHTMLDisplayType_Properties;
			else if ([n isEqual:@"methods"])
				tocMask |= IGKHTMLDisplayType_Methods;
			else if ([n isEqual:@"notifications"])
				tocMask |= IGKHTMLDisplayType_Notifications;
			else if ([n isEqual:@"delegate"])
				tocMask |= IGKHTMLDisplayType_Delegate;
			else if ([n isEqual:@"misc"])
				tocMask |= IGKHTMLDisplayType_Misc;
			else if ([n isEqual:@"bindings"])
				tocMask |= IGKHTMLDisplayType_BindingListings;
		}
		
		*tocMaskPointer = tocMask;
	}
	
	
	// <container-name> . <container-type>
	IGKDocSetManagedObject *container = nil;
	BOOL hasContainer = ([components count] >= 5);
	if (hasContainer)
	{
		NSString *containerComponent = [components objectAtIndex:3];
		
		NSString *containerName = [containerComponent stringByDeletingPathExtension];
		NSString *containerExtension = [containerComponent pathExtension];
		

		if (![containerName length] || ![containerExtension length])
			return nil;
		
		NSString *containerEntity = [self entityNameFromURLComponentExtension:containerExtension];
		if (![containerEntity length])
			return nil;

		NSFetchRequest *containerFetchRequest = [[NSFetchRequest alloc] init];
		[containerFetchRequest setEntity:[NSEntityDescription entityForName:containerEntity inManagedObjectContext:ctx]];
		[containerFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@ && docset == %@", containerName, docset]];
		
		NSError *err = nil;
		NSArray *containers = [ctx executeFetchRequest:containerFetchRequest error:&err];
		
		if (err || ![containers count])
			return nil;

		container = [containers objectAtIndex:0];
	}
	
	
	// <item-name> . <item-type>
	NSString *itemComponent = [components lastObject];
	
	NSString *itemName = [itemComponent stringByDeletingPathExtension];
	NSString *itemExtension = [itemComponent pathExtension];
	if (![itemName length] || ![itemExtension length])
		return nil;

	
	NSString *itemEntity = [self entityNameFromURLComponentExtension:itemExtension];
	if (![itemEntity length])
		return nil;

	NSFetchRequest *itemFetchRequest = [[NSFetchRequest alloc] init];
	[itemFetchRequest setEntity:[NSEntityDescription entityForName:itemEntity inManagedObjectContext:ctx]];

	if (hasContainer)
		[itemFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@ && container == %@ && docset == %@", itemName, container, docset]];
	else
		[itemFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@ && docset == %@", itemName, docset]];
	
	
	NSArray *items = [ctx executeFetchRequest:itemFetchRequest error:&err];
		
	if (err || ![items count])
		return nil;

	return [items objectAtIndex:0];
}

+ (NSString *)entityNameFromURLComponentExtension:(NSString *)ext
{
	if ([ext isEqual:@"class"])
		return @"ObjCClass";
	else if ([ext isEqual:@"category"])
		return @"ObjCCategory";
	else if ([ext isEqual:@"protocol"])
		return @"ObjCProtocol";
	else if ([ext isEqual:@"instance-method"])
		return @"ObjCMethod";
	else if ([ext isEqual:@"class-method"])
		return @"ObjCMethod";
	else if ([ext isEqual:@"property"])
		return @"ObjCProperty";
	else if ([ext isEqual:@"type"])
		return @"CTypedef";
	else if ([ext isEqual:@"enum"])
		return @"CEnum";
	else if ([ext isEqual:@"union"])
		return @"CUnion";
	else if ([ext isEqual:@"struct"])
		return @"CStruct";
	else if ([ext isEqual:@"function"])
		return @"CFunction";
	else if ([ext isEqual:@"global"])
		return @"CGlobal";
	else if ([ext isEqual:@"constant"])
		return @"CConstant";
	else if ([ext isEqual:@"macro"])
		return @"CMacro";
	else if ([ext isEqual:@"notification"])
		return @"ObjCNotification";
	else if ([ext isEqual:@"cpp-struct"])
		return @"CppClassStruct";
	else if ([ext isEqual:@"cpp-member-function"])
		return @"CppMethod";
	else if ([ext isEqual:@"cpp-namespace"])
		return @"CppNamespace";
	else if ([ext isEqual:@"bindings"])
		return @"ObjCBindingsListing";
	
	return @"DocRecord";
}
- (NSString *)URLComponentExtension
{
	NSString *entityName = [[self entity] name];
	if ([entityName isEqual:@"ObjCClass"])
		return @"class";
	else if ([entityName isEqual:@"ObjCCategory"])
		return @"category";
	else if([entityName isEqual:@"ObjCProtocol"])
		return @"protocol";
	else if([entityName isEqual:@"ObjCMethod"])
	{
		if ([[self valueForKey:@"isInstanceMethod"] boolValue])
			return @"instance-method";
		else
			return @"class-method";
	}
	else if ([entityName isEqual:@"ObjCProperty"])
		return @"property";
	else if ([entityName isEqual:@"CTypedef"])
		return @"type";
	else if ([entityName isEqual:@"CEnum"])
		return @"enum";
	else if ([entityName isEqual:@"CUnion"])
		return @"union";
	else if ([entityName isEqual:@"CStruct"])
		return @"struct";
	else if ([entityName isEqual:@"CFunction"])
		return @"function";
	else if ([entityName isEqual:@"CGlobal"])
		return @"global";
	else if ([entityName isEqual:@"CConstant"])
		return @"constant";
	else if ([entityName isEqual:@"CMacro"])
		return @"macro";
	else if ([entityName isEqual:@"ObjCNotification"])
		return @"notification";
	else if ([entityName isEqual:@"CppClassStruct"])
		return @"cpp-struct";
	else if ([entityName isEqual:@"CppMethod"])
		return @"cpp-member-function";
	else if ([entityName isEqual:@"CppNamespace"])
		return @"cpp-namespace";
	else if ([entityName isEqual:@"ObjCBindingsListing"])
		return @"bindings";
	
	return @"unknown";
}
- (NSString *)URLComponent
{
	NSString *n = [self valueForKey:@"name"];
	if (!n)
		n = @"unknown";
	
	return [n stringByAppendingFormat:@".%@", [self URLComponentExtension]];
}
- (NSURL *)docURL:(IGKHTMLDisplayTypeMask)tocMask
{
	IGKDocSetManagedObject *docset = [self valueForKey:@"docset"];
	NSString *host = [docset shortPlatformName];;
	
	NSString *containerComponent = nil;
	if ([self hasKey:@"container"])
		containerComponent = [[self valueForKey:@"container"] URLComponent];
	
	NSString *itemComponent = [self URLComponent];
	
	
	NSString *tocComponent = nil;
	NSMutableArray *tocComponents = [[NSMutableArray alloc] init];
	if (tocMask & IGKHTMLDisplayType_All)
		[tocComponents addObject:@"all"];
	if (tocMask & IGKHTMLDisplayType_Overview)
		[tocComponents addObject:@"overview"];
	if (tocMask & IGKHTMLDisplayType_Tasks)
		[tocComponents addObject:@"tasks"];
	if (tocMask & IGKHTMLDisplayType_Properties)
		[tocComponents addObject:@"properties"];
	if (tocMask & IGKHTMLDisplayType_Methods)
		[tocComponents addObject:@"methods"];
	if (tocMask & IGKHTMLDisplayType_Notifications)
		[tocComponents addObject:@"notifications"];
	if (tocMask & IGKHTMLDisplayType_Delegate)
		[tocComponents addObject:@"delegate"];
	if (tocMask & IGKHTMLDisplayType_Misc)
		[tocComponents addObject:@"misc"];
	if (tocMask & IGKHTMLDisplayType_BindingListings)
		[tocComponents addObject:@"bindings"];
	
	if (![tocComponents count])
		[tocComponents addObject:@"all"];
	
	tocComponent = [tocComponents componentsJoinedByString:@"."];
	
	
	
	NSString *path = @"unknown";
	if ([containerComponent length])
	{
		if ([itemComponent length])
			path = [containerComponent stringByAppendingPathComponent:itemComponent];
		else
			path = containerComponent;
	}
	else
	{
		if ([itemComponent length])
			path = itemComponent;
	}
	
	path = [[[@"/" stringByAppendingPathComponent:[docset shortVersionName]] stringByAppendingPathComponent:tocComponent] stringByAppendingPathComponent:path];
	
	return [[NSURL alloc] initWithScheme:@"ingr-doc" host:host path:path];
}

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
	
	return nil;
	//return [self valueForKey:@"misccontainer"];
}

- (NSString *)xsuperclassname
{
	return [self valueForSoftKey:@"superclass"];
}

- (NSString *)xconforms
{
	return @"";
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
