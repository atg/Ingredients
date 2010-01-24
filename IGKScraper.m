//
//  IGKScraper.m
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKScraper.h"
#import "RegexKitLite.h"

@interface IGKScraper ()

//Extract data out of a file and insert it into the managed object context.
//Returns YES on success (defined as the insertion of a record), NO on failure
- (BOOL)extractPath:(NSString *)extractPath;

@end

@implementation IGKScraper

- (id)initWithDocsetURL:(NSURL *)docsetURL managedObjectContext:(NSManagedObjectContext *)moc
{
	if (self = [super init])
	{
		url = [docsetURL URLByAppendingPathComponent:@"Contents/Resources/Documents/documentation"];
		ctx = moc;
	}
	
	return self;
}

- (void)search
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSLog(@"Started");
	NSLog(@"---");
	NSString *urlpath = [url path];
	NSError *error = nil;
	NSArray *subpaths = [manager subpathsOfDirectoryAtPath:[url path] error:&error];
	if (error)
		return;
	
	NSTimeInterval sint = [NSDate timeIntervalSinceReferenceDate];	
	unsigned count = 0;
	NSMutableArray *extractPaths = [[NSMutableArray alloc] initWithCapacity:1000];
	for (NSString *subpath in subpaths)
	{
		//Ignore non-html files
		if (![[subpath pathExtension] isEqual:@"html"])
			continue;
		
		//Paths to exclude are added in order from most common to least common
		
		NSString *lastPathComponent = [subpath lastPathComponent];
		if ([lastPathComponent isEqual:@"toc.html"])
			continue;
		if ([lastPathComponent isEqual:@"History.html"])
			continue;
		if ([lastPathComponent isEqual:@"index_of_book.html"])
			continue;
		if ([lastPathComponent isEqual:@"RevisionHistory.html"])
			continue;
		if ([lastPathComponent isEqual:@"revision_history.html"])
			continue;
		if ([subpath isLike:@"*RefUpdate/*"])
			continue;
		
		NSArray *pathcomps = [subpath pathComponents];
		NSSet *pathset = [NSSet setWithArray:pathcomps];
		if ([pathset member:@"Conceptual"])
			continue;
		if ([pathset member:@"History"])
			continue;
		if ([pathset member:@"DeveloperTools"])
			continue;
		if ([pathset member:@"gcc"])
			continue;
		//if ([pathset member:@"Introduction"])
		//	continue;
		if ([pathset member:@"qa"])
			continue;
		if ([pathset member:@"samplecode"])
			continue;
		if ([pathset member:@"gdb"])
			continue;
		if ([pathset member:@"SafariWebContent"])
			continue;
		if ([pathset member:@"FoundationRefUpdate"])
			continue;
		
		//If the path ends with index.html and Reference/Reference.html already exists, ignore
		//This is because some index.html files _should_ be parsed, but if a Reference/Reference.html exists, then it should not
		if ([lastPathComponent isEqual:@"index.html"])
		{
			NSString *dir = [urlpath stringByAppendingPathComponent:[subpath stringByDeletingLastPathComponent]];
			if ([manager fileExistsAtPath:[dir stringByAppendingPathComponent:@"Reference/Reference.html"]])
				continue;
			if ([manager fileExistsAtPath:[dir stringByAppendingPathComponent:@"CompositePage.html"]])
				continue;
		}
		
		count++;
		
		[extractPaths addObject:[urlpath stringByAppendingPathComponent:subpath]];
		//NSLog(@"%@", subpath);
	}
	printf("\n");
	NSLog(@"---\n\nSearch %u files. Time %lf", count, [NSDate timeIntervalSinceReferenceDate] - sint);
	NSLog(@"===");
	
	sint = [NSDate timeIntervalSinceReferenceDate];
	
	unsigned failureCount = 0;
	for (NSString *extractPath in extractPaths)
	{
		BOOL success = [self extractPath:extractPath];
		if (!success)
			failureCount++;
		//if (failureCount > 50)
		//	break;
	}
	
	printf("\n");
	NSLog(@"---\n\n %u files failed to parse. Time %lf", failureCount, [NSDate timeIntervalSinceReferenceDate] - sint);
	NSLog(@"===");
}

- (BOOL)extractPath:(NSString *)extractPath
{
	//Let's try to extract the class's name (assuming it is a class of course)
	NSString *regex_className = @"<a name=\"//apple_ref/occ/cl/([a-zA-Z_][a-zA-Z0-9_]*)";
	
	NSError *error = nil;
	NSString *contents = [NSString stringWithContentsOfFile:extractPath encoding:NSUTF8StringEncoding error:&error];
	if (error || !contents)
		return NO;
	
	NSArray *className_captures = [contents captureComponentsMatchedByRegex:regex_className];
	if ([className_captures count] <= 1)
		return NO;
	
	NSLog(@"%@", [className_captures objectAtIndex:1]);
	
	return YES;
}

@end
