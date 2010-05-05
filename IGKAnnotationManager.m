//
//  IKGAnnotationManager.m
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-04-30.
//  Copyright 2010 SilverCocoa. All rights reserved.
//

#import "IGKAnnotationManager.h"
#import "IGKAnnotation.h"

@implementation IGKAnnotationManager

@synthesize annotations;

- (void)loadAnnotationsAtPath:(NSString *)path
{
	[annotations removeAllObjects];
	NSDictionary *annotationDic = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path]];
	// Root object should be a dic..will allow for some meta data like version info etc..
	// annotations should be an array whose keypath is dic.annotations
	
	NSArray *annotationsFromDic = [annotationDic objectForKey:@"annotations"];
	for(NSDictionary *anAnnotation in annotationsFromDic)
	{
		IGKAnnotation *newAnnotation = [[IGKAnnotation alloc] initWithDict:anAnnotation];
		[annotations addObject:newAnnotation];
	}
	
}

#pragma mark Singleton

static IGKAnnotationManager *sharedAnnotationManager = nil;

+ (IGKAnnotationManager *)sharedAnnotationManager
{
    @synchronized(self) {
        if (sharedAnnotationManager == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedAnnotationManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedAnnotationManager == nil) {
            sharedAnnotationManager = [super allocWithZone:zone];
            return sharedAnnotationManager;  // assignment and return on first allocation
        }
    }
    return sharedAnnotationManager; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
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
