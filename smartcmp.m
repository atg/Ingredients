typedef double SmartCmpScore;

static SmartCmpScore lengthScore(NSString *query, NSUInteger queryLength, NSString *a, NSUInteger aLength, id aObject)
{
    SmartCmpScore deltaA = fabs(((double)aLength) - (double)queryLength);
    SmartCmpScore deltaB = fabs(((double)bLength) - (double)queryLength);
    
    double maximumDelta = MAX(deltaA, deltaB);
    
    if (maximumDelta == 0)
        return 0;
    else
        return fabs(deltaA - deltaB) / maximumDelta;
}
static SmartCmpScore caseScore(NSString *query, NSUInteger queryLength, NSString *a, NSUInteger aLength, id aObject)
{
    NSRange range = [a rangeOfString:query options:NSCaseInsensitiveSearch];
    if (range.length == 0 || range.location == NSNotFound)
        return 0;
    
    NSUInteger i = 0;
    SmartCmpScore count = 0;
    for (i = 0; i < range.length; i++)
    {
        unichar qc = [query characterAtIndex:i - range.location]; //Probably shouldn't do this unless everything is ASCII
        unichar rc = [a characterAtIndex:i];
        
        if (qc == rc)
            count++;
    }
    
    return ((SmartCmpScore)(range.length)) / count;
}
static SmartCmpScore anchorScore(NSString *query, NSString *lowercaseQuery, NSString *a, NSString *lowercaseA, id aObject)
{
    if ([lowercaseA isEqual:lowercaseQuery])
        return 1.0;
    else if ([lowercaseA hasPrefix:lowercaseQuery])
        return 0.75;
    else if ([lowercaseA hasSuffix:lowercaseQuery])
        return 0.25;
    else
        return 0.0;
}
static SmartCmpScore frecencyScore(NSString *query, NSString *a, id aObject)
{
    
}
static SmartCmpScore categoryScore(NSString *query, NSString *a, id aObject)
{
    SmartCmpScore score = 0.0;
    int categoryCount = 1;
    
    //Priority
    SmartCmpScore maximumPriorityValue = (SmartCmpScore)(CHPriorityMaximum - 1);
    score += ((SmartCmpScore)[aObject priorityval]) / maximumPriorityValue;
    
    //Docsets
    //TODO: Record most used docsets and score appropriately
    
    return score / ((SmartCmpScore)categoryCount);
}

SmartCmpScore smartcmpScore(NSString *query, NSString *a, id aObject)
{
    SmartCmpScore = smartcmpLength
}

NSComparisonResult smartcmp(NSString *query, NSString *aName, id aObject, NSString *bName, id bObject)
{
    SmartCmpScore aScore = smartcmpScore(query, aName, aObject);
    SmartCmpScore bScore = smartcmpScore(query, bName, bObject);
    
    if (aScore < bScore)
        return NSOrderedAscending;
    else if (aScore > bScore)
        return NSOrderedDescending;
    return NSOrderedSame;
}
 