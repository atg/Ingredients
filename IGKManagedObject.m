//
//  IGKManagedObject.m
//  Ingredients
//
//  Created by Alex Gordon on 08/04/2010.
//  Written in 2010 by Fileability.
//

#import "IGKManagedObject.h"

@implementation IGKManagedObject

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

@end
