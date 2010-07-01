#import "IGKDocRecordManagedObject.h"
#import "smartcmp.h"

//Compute the difference in length between the result and the query
SmartCmpScore lengthScore(NSUInteger queryLength, NSUInteger resultLength, NSUInteger maximumLength)
{
	double delta = fabs(((double)resultLength) - (double)queryLength);
	if (delta == 0.0)
		return 1.0;
    return maximumLength / delta;
}

/*
//Compute the difference in length between, two result strings and the query
SmartCmpScore compare_lengthScore(NSString *query, unichar *queryCharacters, NSUInteger queryLength, NSString *a, unichar *aCharacters, NSUInteger aLength, id aObject)
{
    SmartCmpScore deltaA = fabs(((double)aLength) - (double)queryLength);
    SmartCmpScore deltaB = fabs(((double)bLength) - (double)queryLength);
    
    double maximumDelta = MAX(deltaA, deltaB);
    
    if (maximumDelta == 0)
        return 0.0;
    else
        return fabs(deltaA - deltaB) / maximumDelta;
}
*/

#define MIN3(a,b,c) (a < b ? (a < c ? a : c) : (b < c ? b : c))

int levenshtein(const void *s1, size_t l1,
                const void *s2, size_t l2, size_t nmemb,
                int (*comp)(const void*, const void*))
{
	int i, j;
	size_t len = (l1 + 1) * (l2 + 1);
	char *p1, *p2;
	unsigned int d1, d2, d3, *d, *dp, res;
	
	if (l1 == 0) {
		return l2;
	} else if (l2 == 0) {
		return l1;
	}
	
	d = (unsigned int*)malloc(len * sizeof(unsigned int));
	
	*d = 0;
	for(i = 1, dp = d + l2 + 1;
		i < l1 + 1;
		++i, dp += l2 + 1) {
		*dp = (unsigned) i;
	}
	for(j = 1, dp = d + 1;
		j < l2 + 1;
		++j, ++dp) {
		*dp = (unsigned) j;
	}
	
	for(i = 1, p1 = (char*) s1, dp = d + l2 + 2;
		i < l1 + 1;
		++i, p1 += nmemb, ++dp) {
		for(j = 1, p2 = (char*) s2;
			j < l2 + 1;
			++j, p2 += nmemb, ++dp) {
			if(!comp(p1, p2)) {
				*dp = *(dp - l2 - 2);
			} else {
				d1 = *(dp - 1) + 1;
				d2 = *(dp - l2 - 1) + 1;
				d3 = *(dp - l2 - 2) + 1;
				*dp = MIN3(d1, d2, d3);
			}
		}
	}
	res = *(dp - 2);
	
	dp = NULL;
	free(d);
	return res;
}

//Compute the edit distance between the result and the query. Slower but more accurate than lengthScore().
SmartCmpScore distanceScore(unichar *queryCharacters, NSUInteger queryLength, unichar *resultCharacters, NSUInteger resultLength, NSUInteger maximumLength)
{
	int ldistance = levenshtein(queryCharacters, queryLength, resultCharacters, resultLength, 1, strcasecmp);
	if (ldistance == 0)
		return 1.0;
	
	return ((double)queryLength) / ((double)ldistance);
}

//Compute the number of case-mismatches between the result and the query, given that result is a substring of query
SmartCmpScore caseScore(NSString *query, unichar *queryCharacters, NSUInteger queryLength, NSString *result, unichar *resultCharacters, NSUInteger resultLength)
{
    NSRange range = [result rangeOfString:query options:NSCaseInsensitiveSearch]; //TODO: Replace this with one done on the characters
	if (range.length == 0 || range.location == NSNotFound)
        return 0.0;
	
    NSUInteger i = 0;
    SmartCmpScore count = 0;
    for (i = 0; i < range.length; i++)
    {
        unichar qc = queryCharacters[i]; //Probably shouldn't do this unless everything is ASCII
		unichar rc = resultCharacters[i + range.location];
        
        if (qc == rc)
            count++;
    }
    	
    return ((SmartCmpScore)count) / ((SmartCmpScore)(range.length));
}

//Compute the number of case-mismatches between the result and the query, using a local alignment algorithm. Slower but more accurate than caseScore().
SmartCmpScore alignedCaseScore(NSString *query, unichar *queryCharacters, NSUInteger queryLength, NSString *a, unichar *aCharacters, NSUInteger aLength, id aObject)
{
	//NOT IMPLEMENTED
	return 0.0;
}

//Anchored matches are usually better. The best match is usually an exact match
SmartCmpScore anchorScore(NSString *lowercaseQuery, NSString *lowercaseResult)
{
    if ([lowercaseResult isEqual:lowercaseQuery])
        return 1.0;
    else if ([lowercaseResult hasPrefix:lowercaseQuery])
        return 0.75;
    else if ([lowercaseResult hasSuffix:lowercaseQuery])
        return 0.25;
    else
        return 0.0;
}

//If something is used more frequently, and if something was used recently, then it's probably important
SmartCmpScore frecencyScore()
{
    return 0.0;
}

//Some categories are more important than others
SmartCmpScore categoryScore(id resultObject)
{
    SmartCmpScore score = 0.0;
    int categoryCount = 1;
    
    //Priority
    SmartCmpScore maximumPriorityValue = (SmartCmpScore)(CHPriorityMaximum - 1);
    score += ((SmartCmpScore)[resultObject priorityval]) / maximumPriorityValue;
    
    //Docsets
    //TODO: Record most used docsets and score appropriately
    
    return score / ((SmartCmpScore)categoryCount);
}

#define smartcmp_apply_piece(f) f(query, queryCharacters, a, unichar *aCharacters, aObject)

SmartCmpScore smartcmpScore(NSString *query,  NSString *lowercaseQuery,  unichar *queryCharacters,  NSUInteger queryLength,
							NSString *result, NSString *lowercaseResult, unichar *resultCharacters, NSUInteger resultLength, id resultObject,
							NSUInteger maximumLength)
{
	//SmartCmpScore length_s = lengthScore(queryLength, resultLength, maximumLength);
	SmartCmpScore distance_s = distanceScore(queryCharacters, queryLength, resultCharacters, resultLength, maximumLength);
	SmartCmpScore case_s = caseScore(query, queryCharacters, queryLength, result, resultCharacters, resultLength);
	SmartCmpScore anchor_s = anchorScore(lowercaseQuery, lowercaseResult);
	SmartCmpScore frecency_s = 0.0; //frecencyScore(...);
	SmartCmpScore category_s = categoryScore(resultObject);
	
    SmartCmpScore s = //length_s
					+ distance_s
					+ 0.75 * case_s
					+ anchor_s
					+ frecency_s
					+ 2.0 * category_s
					;
					
	//NSLog(@"d %lf, c %lf, a %lf, f %lfm k %lf; t %lf; '%@'", distance_s, case_s, anchor_s, frecency_s, category_s, s, result);
	return s;
}

NSComparisonResult smartcmp(NSString *query,   NSString *lowercaseQuery,   unichar *queryCharacters,   NSUInteger queryLength,
							NSString *resultA, NSString *lowercaseResultA, unichar *resultACharacters, NSUInteger resultALength, id resultAObject,
							NSString *resultB, NSString *lowercaseResultB, unichar *resultBCharacters, NSUInteger resultBLength, id resultBObject,
							NSUInteger maximumLength)
{
    SmartCmpScore aScore = smartcmpScore(query, lowercaseQuery, queryCharacters, queryLength,
										 resultA, lowercaseResultA, resultACharacters, resultALength, resultAObject,
										 maximumLength);
    SmartCmpScore bScore = smartcmpScore(query, lowercaseQuery, queryCharacters, queryLength,
										 resultB, lowercaseResultB, resultACharacters, resultBLength, resultBObject,
										 maximumLength);
    
    if (aScore < bScore)
        return NSOrderedAscending;
    else if (aScore > bScore)
        return NSOrderedDescending;
    return NSOrderedSame;
}
 