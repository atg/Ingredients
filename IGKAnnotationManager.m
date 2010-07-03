//
//  IKGAnnotationManager.m
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-04-30.
//  Written in 2010 by SilverCocoa.
//

#import "IGKAnnotationManager.h"
#import "IGKAnnotation.h"

const int IGKAnnotationVersion = 1;

@implementation IGKAnnotationManager

@synthesize annotations;

- (BOOL)loadAnnotations
{
	
	NSString *loadPath = [[[[NSApp delegate] kitController] applicationSupportDirectory] stringByAppendingPathComponent:@"Annotations.plist"];
	if([[NSFileManager defaultManager] fileExistsAtPath:loadPath])
	{
		[self loadAnnotationsAtPath:loadPath];
		return YES;
	}
	
	return NO;
}

- (void)saveAnnotations
{
	NSString *savePath = [[[[NSApp delegate] kitController] applicationSupportDirectory] stringByAppendingPathComponent:@"Annotations.plist"];
	[self saveAnnotationsAtPath:savePath];
}


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

- (void)saveAnnotationsAtPath:(NSString *)path
{
	NSMutableDictionary *saveDic = [[NSMutableDictionary alloc] init];
	NSMutableArray *saveArray = [[NSMutableArray alloc] init];
	
	[saveDic setObject:[NSNumber numberWithInt:IGKAnnotationVersion] forKey:@"version"];
	
	for(IGKAnnotation *anAnnotation in annotations)
	{
		[saveArray addObject:[anAnnotation annotationAsDict]];
	}
	[saveDic setObject:saveArray forKey:@"annotations"];
	
	[saveDic writeToURL:[NSURL fileURLWithPath:path] atomically:YES];
	
}

- (void)addAnnotation:(IGKAnnotation *)newAnnotation
{
	[annotations addObject:newAnnotation];
	[self saveAnnotations];
}

- (NSArray *)annotationsForURL:(NSString *)URL
{
	//FIXME: This could be made faster by using a pregenerated dictionary of URLs -> sorted annotation arrays
	
	NSMutableArray *subset = [[NSMutableArray alloc] init];
	
	for (IGKAnnotation *a in annotations)
	{
		if ([[a docurl] isCaseInsensitiveEqual:URL])
		{
			[subset addObject:a];
		}
	}
	
	return [subset sortedArrayUsingSelector:@selector(compare:)];
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
