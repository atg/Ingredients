//
//  IGKScraper.m
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKScraper.h"


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
		if ([pathset member:@"Introduction"])
			continue;
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
		
		//NSLog(@"%@", subpath);
	}
	printf("\n");
	NSLog(@"---\n\nSearch %u files. Time %lf", count, [NSDate timeIntervalSinceReferenceDate] - sint);
	NSLog(@"===");
}

@end
