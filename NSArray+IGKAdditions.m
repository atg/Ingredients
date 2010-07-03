//
//  NSArray+IGKAdditions.m
//  Ingredients
//
//  Created by Alex Gordon on 18/06/2010.
//  Written in 2010 by Fileability.
//

#import "NSArray+IGKAdditions.h"
#import "smartcmp.h"

NSComparisonResult IGKInverseComparisonResult(NSComparisonResult result)
{
	if (result == NSOrderedAscending)
		return NSOrderedDescending;
	if (result == NSOrderedDescending)
		return NSOrderedAscending;
	return NSOrderedSame;
}

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
		NSComparisonResult comparisonResult = IGKInverseComparisonResult([[a objectAtIndex:0] compare:[b objectAtIndex:0]]);
		if (comparisonResult == NSOrderedSame)
		{
			//If we're really desperate we can compare the lengths of the contents
			if ([[a objectAtIndex:1] respondsToSelector:@selector(lengthOfContent)])
			{
				return IGKInverseComparisonResult([[[a objectAtIndex:1] lengthOfContent] compare:[[b objectAtIndex:1] lengthOfContent]]);
			}
			
			return [[[a objectAtIndex:1] valueForKey:@"name"] compare:[[b objectAtIndex:1] valueForKey:@"name"]];
		}
		
		return comparisonResult;
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
