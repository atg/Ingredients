//
//  NSArray+IGKAdditions.m
//  Ingredients
//
//  Created by Alex Gordon on 18/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSArray+IGKAdditions.h"
#import "smartcmp.h"

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
	
	if (index >= [self count])
		return nil;
	
	return [self objectAtIndex:index];
}

- (NSArray *)smartSort:(NSString *)query
{
	//Note some commonly used information about the query
	NSString *lowercaseQuery = [query lowercaseString];
	NSUInteger queryLength = [query length];
	
	unichar *queryCharacters = malloc(queryLength * sizeof(unichar));
	[query getCharacters:queryCharacters range:NSMakeRange(0, queryLength)];
	
	
	//Find the length of the longest name
	NSUInteger maximumLength = 1.0;
	for (id obj in self)
	{
		NSString *result = [obj valueForKey:@"name"];
		
		if ([result length] > maximumLength)
			maximumLength = [result length];
	}
	
	
	//Iterate the array and score each item
	NSMutableArray *scores = [[NSMutableArray alloc] initWithCapacity:[self count]];
	for (id obj in self)
	{
		NSString *result = [obj valueForKey:@"name"];
		NSString *lowercaseResult = [result lowercaseString];
		NSUInteger resultLength = [result length];
		
		unichar *resultCharacters = malloc(resultLength * sizeof(unichar));
		[result getCharacters:resultCharacters range:NSMakeRange(0, resultLength)];
		
		SmartCmpScore score = smartcmpScore(query, lowercaseQuery, queryCharacters, queryLength,
											result, lowercaseResult, resultCharacters, resultLength, obj,
											maximumLength);
		
		[scores addObject:[NSArray arrayWithObjects:[NSNumber numberWithDouble:score], obj, nil]];
		
		free(resultCharacters);
	}
	
	
	//Sort the scores
	NSArray *sortedScores = [scores sortedArrayUsingComparator:^ NSComparisonResult (id a, id b) {
		NSComparisonResult comparisonResult =  [[a objectAtIndex:0] compare:[b objectAtIndex:0]];
		if (comparisonResult == NSOrderedAscending)
			return NSOrderedDescending;
		else if (comparisonResult == NSOrderedDescending)
			return NSOrderedAscending;
		return NSOrderedSame;
	}];
	
	
	//Clean up
	free(queryCharacters);
	
	
	//Return the sorted objects
	NSMutableArray *sortedObjects = [[NSMutableArray alloc] initWithCapacity:[self count]];
	for (id obj in sortedScores)
	{
		[sortedObjects addObject:[obj objectAtIndex:1]];
	}
	
	
	return sortedObjects;
}

@end
