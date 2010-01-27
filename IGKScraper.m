//
//  IGKScraper.m
//  Ingredients
//
//  Created by Alex Gordon on 24/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKScraper.h"
#import "RegexKitLite.h"
#import "IGKDocRecordManagedObject.h"

@interface IGKScraper ()

//Extract data out of a file and insert it into the managed object context.
//Returns YES on success (defined as the insertion of a record), NO on failure
- (BOOL)extractPath:(NSString *)extractPath docset:(NSManagedObject *)docset;
- (NSManagedObject *)addRecordNamed:(NSString *)recordName
							 ofType:(NSString *)recordType
							   desc:(NSString *)recordDesc
						 sourcePath:(NSString *)recordPath;

@end

@implementation IGKScraper

- (id)initWithDocsetURL:(NSURL *)theDocsetURL managedObjectContext:(NSManagedObjectContext *)moc
{
	if (self = [super init])
	{
		docsetURL = [theDocsetURL copy];
		url = [docsetURL URLByAppendingPathComponent:@"Contents/Resources/Documents/documentation"];
		ctx = moc;
	}
	
	return self;
}

- (void)search
{
	//Get the info.plist
	NSDictionary *infoPlist = [[NSDictionary alloc] initWithContentsOfURL:[docsetURL URLByAppendingPathComponent:@"Contents/info.plist"]];
	NSString *bundleIdentifier = [infoPlist objectForKey:@"CFBundleIdentifier"];
	NSString *version = [infoPlist objectForKey:@"CFBundleVersion"];
	if (bundleIdentifier && version)
	{
		//Find out if we've already parsed
		NSPredicate *countPredicate = [NSPredicate predicateWithFormat:@"bundleIdentifier == %@ and version == %@", bundleIdentifier, version];
		
		NSError *error = nil;
		NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
		[fetch setEntity:[NSEntityDescription entityForName:@"Docset" inManagedObjectContext:ctx]];
		[fetch setPredicate:countPredicate];
		NSUInteger recordCount = [ctx countForFetchRequest:fetch error:&error];
		if (!error && recordCount > 0)
		{
			//There's already some records - don't parse
			NSLog(@"Docset already exists: %@ / %@", version, bundleIdentifier);
			return;
		}
	}
	
	
	//*** Create a docset object ***
	NSEntityDescription *docsetEntity = [NSEntityDescription entityForName:@"Docset" inManagedObjectContext:ctx];
	
	NSManagedObject *docset = [[IGKDocRecordManagedObject alloc] initWithEntity:docsetEntity insertIntoManagedObjectContext:ctx];
	
	if (bundleIdentifier)
		[docset setValue:bundleIdentifier forKey:@"bundleIdentifier"];
	if (version)
		[docset setValue:version forKey:@"version"];
	
	if ([infoPlist objectForKey:@"DocSetDescription"])
		[docset setValue:[infoPlist objectForKey:@"DocSetDescription"] forKey:@"docsetDescription"];
	if ([infoPlist objectForKey:@"DocSetFeedName"])
		[docset setValue:[infoPlist objectForKey:@"DocSetFeedName"] forKey:@"feedName"];
	if ([infoPlist objectForKey:@"DocSetFeedURL"])
		[docset setValue:[infoPlist objectForKey:@"DocSetFeedURL"] forKey:@"feedURL"];
	if ([infoPlist objectForKey:@"DocSetPlatformFamily"])
		[docset setValue:[infoPlist objectForKey:@"DocSetPlatformFamily"] forKey:@"platformFamily"];
	if ([infoPlist objectForKey:@"DocSetPlatformVersion"])
		[docset setValue:[infoPlist objectForKey:@"DocSetPlatformVersion"] forKey:@"platformVersion"];
	if ([infoPlist objectForKey:@"DocSetFallbackURL"])
		[docset setValue:[infoPlist objectForKey:@"DocSetFallbackURL"] forKey:@"fallbackURL"];
	
	[docset setValue:[docsetURL absoluteString] forKey:@"url"];
	
	
	
	//*** Do the actual parsing ***
	//TODO: Use GCD to make this an actual background search
	//dispatch_async(dispatch_get_global_queue(0, 0), ^{
		
	[self backgroundSearch:docset];
		
	//	dispatch_async(dispatch_get_main_queue(), ^{
			[ctx save:nil];
			[ctx reset];
	//	});
	//});
	
	
#ifndef NDEBUG
	//*** Show and tell ***
	
	/*
	NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"DocRecord" inManagedObjectContext:ctx]];
	[fetch setResultType:NSManagedObjectResultType];
	[fetch setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	for (NSManagedObject *obj in [ctx executeFetchRequest:fetch error:nil])
	{
		NSLog(@"Managed object = %@", [obj valueForKey:@"name"]);
	}
	 */
#endif
}
- (void)backgroundSearch:(NSManagedObject *)docset
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
		BOOL success = [self extractPath:extractPath docset:docset];
		if (!success)
			failureCount++;
		//if (failureCount > 50)
		//	break;
	}
		
	printf("\n");
	NSLog(@"---\n\n %u files failed to parse. Time %lf", failureCount, [NSDate timeIntervalSinceReferenceDate] - sint);
	NSLog(@"===");
}

- (NSManagedObject *)addRecordNamed:(NSString *)recordName
						 entityName:(NSString *)entityName
							   desc:(NSString *)recordDesc
						 sourcePath:(NSString *)recordPath
{
	NSEntityDescription *ed = [NSEntityDescription entityForName:entityName inManagedObjectContext:ctx];
	
	NSManagedObject *newRecord = [[IGKDocRecordManagedObject alloc] initWithEntity:ed insertIntoManagedObjectContext:ctx];
	
	[newRecord setValue:recordName forKey:@"name"];
	[newRecord setValue:recordDesc forKey:@"overview"];
	[newRecord setValue:recordPath forKey:@"documentPath"];
	
	return newRecord;
}

- (BOOL)extractPath:(NSString *)extractPath docset:(NSManagedObject *)docset
{
	//Let's try to extract the class's name (assuming it is a class of course)	
	NSError *error = nil;
	NSString *contents = [NSString stringWithContentsOfFile:extractPath encoding:NSUTF8StringEncoding error:&error];
	if (error || !contents)
		return NO;
	
	
	//Parse the item's name and kind
	NSString *regex_className = @"<a name=\"//apple_ref/occ/([a-z_]+)/([a-zA-Z_][a-zA-Z0-9_]*)";
	NSArray *className_captures = [contents captureComponentsMatchedByRegex:regex_className];
	if ([className_captures count] < 3)
		return NO;
	
	NSString *type = [className_captures objectAtIndex:1];
	NSString *name = [className_captures objectAtIndex:2];
	
	/* Common types
		cl		- class
		intf	- protocol
		instm	- old/deprecated classes
		intfm	- old/deprecated protocols
		cat		- category
		binding - bindings listing
	 */
	
	NSString *entityName = nil;
	if ([type isEqual:@"cl"] || [type isEqual:@"instm"])
		entityName = @"ObjCClass";
	
	else if ([type isEqual:@"cat"])
		entityName = @"ObjCCategory";
	
	else if ([type isEqual:@"intf"] || [type isEqual:@"intfm"])
		entityName = @"ObjCProtocol";
	
	else if ([type isEqual:@"binding"])
	    entityName = @"ObjCBindingsListing";
	
	//If we don't understand the entity name, bail
	if (!entityName)
		return NO;
	
	//Parse the abstract
	NSString *regex_abstract = @"<a name=\"[^\"]+\" title=\"Overview\"></a>[ \\t\\n]*<h2[^>]+>Overview</h2>(.+?)((<a name=\"[^\"]+\" title=\"[^\"]+\"></a>[ \\t\\n]*<h2 class=\"jump\">)|(<div id=\"pageNavigationLinks\"))"; //@"<div [^>]*id=\"Overview_section\"[^>]*>(.+)</div>\\s*<a name=";
	NSArray *abstract_captures = [contents captureComponentsMatchedByRegex:regex_abstract
																   options:(RKLDotAll|RKLCaseless)
																	 range:NSMakeRange(0, [contents length])
																	 error:nil];
	NSString *abstract = nil;
	if ([abstract_captures count] >= 2)
		abstract = [abstract_captures objectAtIndex:1];
	
	//Deprecation appendicies and bindings listings have no abstract
	
	if ([abstract length] == 0)
	{
		//NSLog(@"ZERO - %@ - %@ - %@", type, name, extractPath);
		abstract = @"";
	}
	else
	{
		//NSLog(@"%@ - %@ - %u", type, name, [abstract length]);
	}
	
	NSManagedObject *obj = [self addRecordNamed:name entityName:entityName desc:abstract sourcePath:extractPath];
	[obj setValue:docset forKey:@"docset"];
	
	NSString *regex_instanceMethodBlock = @"<h2 class=\"jump\">\\s*Instance Methods\\s*</h2>(.+?)(<h2 class=\"jump\">|<p class=\"content_text\" lang=\"en\" dir=\"ltr\">)";
	NSString *instanceMethodMatch = [contents stringByMatching:regex_instanceMethodBlock
													   options:(RKLDotAll|RKLCaseless)
													   inRange:NSMakeRange(0, [contents length])
													   capture:0
														 error:nil];
	
	if ([instanceMethodMatch length])
	{
		NSEntityDescription *methodEntity = [NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:ctx];
		
		NSString *regex_instanceMethod = [NSString stringWithFormat:@"<a name=\"//apple_ref/occ/instm/%@/([a-zA-Z0-9_$:]+)\" title=\"([a-zA-Z0-9_$:]+)\">", name];
		NSArray *methods = [instanceMethodMatch componentsSeparatedByRegex:regex_instanceMethod];
		
		for (NSString *method in methods)
		{			
			//Method name
			NSString *methodName = [method stringByMatching:@"<h3 class=\"jump instanceMethod\">([^<>]+)</h3>" capture:1];
			if (methodName == nil)
				continue;
			
			IGKDocRecordManagedObject *newMethod = [[IGKDocRecordManagedObject alloc] initWithEntity:methodEntity insertIntoManagedObjectContext:ctx];
			
			//Method abstract
			NSString *methodAbstract = [method stringByMatching:@"</h3>\\s*<p class=\"spaceabove\">([^<>]+)</p>" capture:1];
			
			//Method Signature
			NSString *methodSignature = [method stringByMatching:@"<p class=\"spaceabovemethod\">(.+?)</p>" capture:1];
			methodSignature = [methodSignature stringByReplacingOccurrencesOfRegex:@"<a\\s+[^>]+>(.+?)</a>" withString:@"$1"];
			
			[newMethod setValue:methodName forKey:@"name"];
			[newMethod setValue:obj forKey:@"container"];
			[newMethod setValue:docset forKey:@"docset"];
			[newMethod setValue:methodSignature forKey:@"signature"];

			if ([methodAbstract length])
				[newMethod setValue:methodAbstract forKey:@"overview"];
		}
	}
	
	
	return YES;
}

@end
