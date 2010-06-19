//
//  NSArray+IGKAdditions.m
//  Ingredients
//
//  Created by Alex Gordon on 18/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSArray+IGKAdditions.h"


@implementation NSArray (IGKAdditions)

- (NSArray *)igk_map:(id (^)(id obj))rule
{
	NSMutableArray *filteredArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
	
	for (id obj in self)
	{
		id image = rule(obj);
		if (image)
			[filteredArray addObject:image];
	}
	
	return filteredArray;
}
- (NSArray *)igk_filter:(BOOL (^)(id obj))predicate
{
	NSMutableArray *mappedArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
	
	for (id obj in self)
	{
		if (predicate(obj))
			[mappedArray addObject:obj];
	}
	
	return mappedArray;
}

- (NSArray *)igk_firstObject
{
	return [self igk_objectAtSoftIndex:0];
}
- (NSArray *)igk_objectAtSoftIndex:(NSInteger)index
{	
	if (index < 0)
		return [self igk_objectAtSoftIndex:[self count] + index];
	
	if (index > [self count])
		return nil;
	
	return [self objectAtIndex:index];
}

@end
