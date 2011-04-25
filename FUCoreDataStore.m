//
//  FUCoreDataStore.m
//  Ingredients
//
//  Created by Alex Gordon on 22/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FUCoreDataStore.h"
#import "IGKDocRecordManagedObject.h"

@implementation NSManagedObjectContext (FUCoreData)

- (FUCoreDataStore *)fffffffuuuuuuuuuuuu
{
	return [[FUCoreDataStore alloc] initWithManagedObjectContext:self];
}

@end


@implementation FUCoreDataStore

@synthesize database;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)ctx
{
	if (self = [super init])
	{
		NSPersistentStoreCoordinator *pc = [ctx persistentStoreCoordinator];
		NSURL *databaseURL = [pc URLForPersistentStore:[[pc persistentStores] igk_firstObject]];
		
		database = [FMDatabase databaseWithPath:[databaseURL path]];
		[database setShouldCacheStatements:YES];
		[database open];
		
		context = ctx;
		
		if (!database)
			return nil;
		
		relationshipToEntityMap = [[NSMutableDictionary alloc] init];
		NSManagedObjectModel *model = [pc managedObjectModel];
		for (NSEntityDescription *ent in [model entities])
		{
			NSDictionary *mapping = [ent relationshipsByName];
			for (NSString *relName in mapping)
			{
				NSRelationshipDescription *rel = [mapping valueForKey:relName];
				[relationshipToEntityMap setValue:[[rel destinationEntity] name] forKey:relName];
			}
		}
	}
	
	return self;
}

- (void)finalize
{
	[database close];
	[super finalize];
}

- (id)emptyMagicObject
{
	FUCoreDataMagicObject *obj = [[FUCoreDataMagicObject alloc] init];
	obj.store = self;
	obj.scalarKeyMap = scalarKeyMap;
	obj.relationshipToEntityMap = relationshipToEntityMap;
	
	return obj;
}
- (id)magicObjectForEntity:(NSString *)normalEntityName rowid:(id)rowid
{
	NSString *coredataizedEntityName = [FUCoreDataMagicObject coredataizeKey:normalEntityName];
	
	FMResultSet *resultSet = [database executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE ZROWID=?", coredataizedEntityName], rowid];
	
	id mobj = nil;
	if ([resultSet next])
	{
		mobj = [self magicObjectForResultSet:resultSet];
	}
	[resultSet close];
	
	return mobj;
}
- (id)magicObjectForResultSet:(FMResultSet *)resultSet
{
	NSDictionary *resultDict = [resultSet resultDict];
	
	FUCoreDataMagicObject *obj = [self emptyMagicObject];
	obj.results = resultDict;

	return obj;
}
- (NSArray *)magicObjectsForResultSet:(FMResultSet *)resultSet
{
	NSMutableArray *mobjs = [[NSMutableArray alloc] init];
	
	while ([resultSet next])
	{
		id mobj = [self magicObjectForResultSet:resultSet];
		if (mobj)
			[mobjs addObject:mobj];
	}
	return mobjs;
}

@end

/*
@interface _NSScalarObjectID : NSObject
{
}

- (long long)_referenceData64;
- (id)_retainedURIString;
- (void)dealloc;
- (id)initWithPK64:(long long)arg1;

@end
*/

@implementation FUCoreDataMagicObject

@synthesize store;
@synthesize scalarKeyMap;
@synthesize relationshipToEntityMap;
@synthesize results;
@synthesize managedObject;

/*- (BOOL)isKindOfEntityNamed:(NSString *)entityName
{
	NSManagedObjectContext *ctx = [self managedObjectContext];
	return [[self entity] isKindOfEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:ctx]];
}*/
- (BOOL)hasKey:(NSString *)key
{
	return [self valueForKey:key] != nil;
}
- (id)valueForSoftKey:(NSString *)key
{
	return [self valueForKey:key];
}

- (id)resolveManagedObject
{
	//Class f_NSScalarObjectID = NSClassFromString(@"_NSScalarObjectID");
	//id objid = [[f_NSScalarObjectID alloc] initWithPK64:[[results objectForKey:@"Z_PK"] longLongValue]];
	
	
	// So the problem is we NEED to find some way of resolving as managed objects.
	// OR we need to be able to convert the whole of the reading side of the app to managed objects
	// Either way, it's difficult
	
	NSLog(@"TODO: IMPLEMENT RESOLVING MANAGED OBJECTS");
	exit(1);
	
	
	return managedObject;
}
- (id)valueForKey:(id)key
{
	// Is this a releationship?
	NSString *mappedEntity = [relationshipToEntityMap objectForKey:key];
	id result = [results objectForKey:[self coredataizeKeyInMagicObject:key]];
	
	if (mappedEntity)
	{
		// Follow the relationship
		return [store magicObjectForEntity:mappedEntity rowid:result];
	}
	
	// If there's no result, fall back to core data
	if (result == nil)
	{
		NSLog(@"Oops no result for key '%@'", key);
		return [[self resolveManagedObject] valueForSoftKey:key];
	}
	
	// Otherwise just return the result
	return result;
}
- (NSString *)coredataizeKeyInMagicObject:(NSString *)normalKey
{
	return [scalarKeyMap objectForKey:normalKey] ?: [[self class] coredataizeKey:normalKey];
}
+ (NSString *)coredataizeKey:(NSString *)normalKey
{
	// Uppercase
	normalKey = [normalKey uppercaseString];
	
	// Prepend a Z
	normalKey = [@"Z" stringByAppendingString:normalKey];
	
	return normalKey;
}

#define CALLINPLACE(proxy, ...) return [[proxy class] instanceMethodForSelector:_cmd](self, _cmd, ## __VA_ARGS__)

- (NSString *)pageTitle:(IGKHTMLDisplayTypeMask)mask
{
	CALLINPLACE(IGKDocRecordManagedObject, mask);
}
- (NSMutableArray *)getSuperclasses
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSMutableArray *)getSubclasses
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (id)findNearestClassWithName:(NSString *)className
{
	CALLINPLACE(IGKDocRecordManagedObject, className);
}
/*
- (NSString *)URLComponentExtension
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSString *)URLComponent
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSURL *)docURL:(IGKHTMLDisplayTypeMask)tocMask
{
	CALLINPLACE(IGKDocRecordManagedObject, tocMask);
}
*/
- (NSString *)documentPath
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
//- (void)setDocumentPath:(NSString *)docpath
//- (void)awakeFromInsert
- (CHRecordPriority)priorityval
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSString *)xcontainername
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (IGKDocRecordManagedObject *)xcontainer
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSString *)xsuperclassname
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSString *)xconforms
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSString *)xdocset
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSImage *)normalIcon
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSImage *)selectedIcon
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (CHSymbolButtonImageMask)iconMask
{
	CALLINPLACE(IGKDocRecordManagedObject);
}
- (NSImage *)iconForSelectedState:(BOOL)isSelected
{
	CALLINPLACE(IGKDocRecordManagedObject, isSelected);
}
- (NSNumber *)lengthOfContent
{
	CALLINPLACE(IGKDocRecordManagedObject);
}



#pragma mark NSManagedObject fallback

- (id)actionForwardee
{
	return [self resolveManagedObject];
}
- (BOOL)respondsToSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
		return YES;
	if ([[NSManagedObject class] respondsToSelector:aSelector])
		return YES;
	return NO;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector])
		return [super methodSignatureForSelector:aSelector];
	
	id forwardee = [self actionForwardee];
	if ([forwardee respondsToSelector:aSelector])
		return [forwardee methodSignatureForSelector:aSelector];
	
	return [super methodSignatureForSelector:aSelector];
}
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	id forwardee = [self actionForwardee];
	
	if ([forwardee respondsToSelector:[anInvocation selector]])
	{
		[anInvocation invokeWithTarget:forwardee];
	}
	else
	{
		[super forwardInvocation:anInvocation];
	}
}

@end