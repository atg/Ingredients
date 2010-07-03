//
//  IGKWordMembership.m
//  Ingredients
//
//  Created by Alex Gordon on 02/05/2010.
//  Written in 2010 by Fileability.
//

#import "IGKWordMembership.h"


@implementation IGKWordMembership

- (id)initWithCapacity:(NSUInteger)capacity
{
	if (self = [super init])
	{
		words = [[NSHashTable alloc] initWithOptions:NSHashTableStrongMemory capacity:capacity];
	}
}
- (void)addWord:(NSString *)word
{
	[words addObject:word];
}

- (NSString *)addHyperlinksToPassage:(NSString *)passage
{
	NSUInteger length = [passage length];
	
	NSMutableString *newString = [[NSMutableString alloc] initWithCapacity:length];
	__block NSRange previousRange = NSMakeRange(0, 0);
	
	[passage enumerateSubstringsInRange:NSMakeRange(0, length)
								options:NSStringEnumerationByWords
							 usingBlock:
	^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSInteger inbetweenLength = substringRange.location - NSMaxRange(previousRange);
		if (inbetweenLength > 0)
		{
			[newString appendString:[passage substringWithRange:NSMakeRange(NSMaxRange(previousRange), inbetweenLength)]];
		}
		
		if ([substring length] > 1 && [words containsObject:substring])
		{
			[newString appendString:@"<a href='http://ingr-link/"];
			[newString appendString:substring];
			[newString appendString:@"' class='semistealth'><span>"];
			[newString appendString:substring];
			[newString appendString:@"</span></a>"];
		}
		else
		{
			[newString appendString:substring];
		}
		
		previousRange = substringRange;
	}];
	
	NSInteger inbetweenLength = length - NSMaxRange(previousRange);
	if (inbetweenLength > 0)
	{
		[newString appendString:[passage substringWithRange:NSMakeRange(NSMaxRange(previousRange), inbetweenLength)]];
	}
	
	return newString;
}

#pragma mark Singleton

static IGKWordMembership *sharedManager = nil;

+ (IGKWordMembership *)sharedManager
{
	return [self sharedManagerWithCapacity:0];
}
+ (IGKWordMembership *)sharedManagerWithCapacity:(NSUInteger)capacity
{
    @synchronized(self) {
        if (sharedManager == nil) {
            [[self alloc] initWithCapacity:capacity]; // assignment not done here
        }
    }
    return sharedManager;
}
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [super allocWithZone:zone];
            return sharedManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
- (id)retain
{
    return self;
}
- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}
- (void)release
{
    //do nothing
}
- (id)autorelease
{
    return self;
}

@end
