/*
 *  smartcmp.h
 *  Ingredients
 *
 *  Created by Alex Gordon on 30/06/2010.
 *  Written in 2010 by Fileability.
 *
 */

typedef double SmartCmpScore;

//Compute the difference in length between the result and the query
SmartCmpScore lengthScore(NSUInteger queryLength, NSUInteger resultLength, NSUInteger maximumLength);

//Compute the edit distance between the result and the query. Slower but more accurate than lengthScore().
SmartCmpScore distanceScore(unichar *queryCharacters, NSUInteger queryLength, unichar *resultCharacters, NSUInteger resultLength, NSUInteger maximumLength);

//Compute the number of case-mismatches between the result and the query, given that result is a substring of query
SmartCmpScore caseScore(NSString *query, unichar *queryCharacters, NSUInteger queryLength, NSString *result, unichar *resultCharacters, NSUInteger resultLength);

//Compute the number of case-mismatches between the result and the query, using a local alignment algorithm. Slower but more accurate than caseScore().
//SmartCmpScore alignedCaseScore(NSString *query, unichar *queryCharacters, NSUInteger queryLength, NSString *a, unichar *aCharacters, NSUInteger aLength, id aObject);

//Anchored matches are usually better. The best match is usually an exact match
SmartCmpScore anchorScore(NSString *lowercaseQuery, NSString *lowercaseResult);

//If something is used more frequently, and if something was used recently, then it's probably important
//SmartCmpScore frecencyScore(...);

//Some categories are more important than others
SmartCmpScore categoryScore(id resultObject);



SmartCmpScore smartcmpScore(NSString *query,  NSString *lowercaseQuery,  unichar *queryCharacters,  NSUInteger queryLength,
							NSString *result, NSString *lowercaseResult, unichar *resultCharacters, NSUInteger resultLength, id resultObject,
							NSUInteger maximumLength);

NSComparisonResult smartcmp(NSString *query,   NSString *lowercaseQuery,   unichar *queryCharacters,   NSUInteger queryLength,
							NSString *resultA, NSString *lowercaseResultA, unichar *resultACharacters, NSUInteger resultALength, id resultAObject,
							NSString *resultB, NSString *lowercaseResultB, unichar *resultBCharacters, NSUInteger resultBLength, id resultBObject,
							NSUInteger maximumLength);