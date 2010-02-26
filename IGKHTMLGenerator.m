//
//  IGKHTMLGenerator.m
//  Ingredients
//
//  Created by Alex Gordon on 26/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKHTMLGenerator.h"
#import "IGKScraper.h"

@interface IGKHTMLGenerator ()

- (NSString *)escape:(NSString *)unescapedText;

- (void)header;
- (void)footer;

- (void)html_all;
- (void)html_overview;
- (void)html_tasks;
- (void)html_properties;
- (void)html_methods;
- (void)html_notifications;
- (void)html_delegate;

- (void)html_method:(IGKDocRecordManagedObject *)obj;

@end


@implementation IGKHTMLGenerator

@synthesize context;
@synthesize managedObject;
@synthesize displayType;

//Take an unescaped string and add escapes for <, >, &, ", '
- (NSString *)escape:(NSString *)unescapedText
{
	NSMutableString *str = [unescapedText mutableCopy];
	
	[str replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
	[str replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
	[str replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
	[str replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
	[str replaceOccurrencesOfString:@"'" withString:@"&apos;" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
	
	return str;
}

- (void)header
{	
	[outputString appendFormat:@"<!doctype html>\n<html>\n<head>\n<meta charset='utf-8'>\n<title>%@</title>\n<link rel='stylesheet' href='main.css' type='text/css' media='screen'>\n</head>\n<body>\n", [transientObject valueForKey:@"name"]];
}
- (void)footer
{
	[outputString appendString:@"</body>\n</html>\n"];
}

- (void)setManagedObject:(IGKDocRecordManagedObject *)mo
{
	[fullScraper cleanUp];
	
	//Do a full scrape of the documentation referenced by managedObject
	fullScraper = [[IGKFullScraper alloc] initWithManagedObject:managedObject];
	[fullScraper start];
	
	transientContext = fullScraper.transientContext;
	transientObject = (IGKDocRecordManagedObject *)(fullScraper.transientObject);
}
- (void)finalize
{
	fullScraper = nil;
	[super finalize];
}

- (IGKHTMLDisplayTypeMask)displayTypes
{
	return IGKHTMLDisplayType_All | IGKHTMLDisplayType_Overview | IGKHTMLDisplayType_Tasks | IGKHTMLDisplayType_Properties | IGKHTMLDisplayType_Methods | IGKHTMLDisplayType_Notifications | IGKHTMLDisplayType_Delegate;
}

- (NSString *)html
{
	if (!managedObject)
		return @"";
	
	//Create a string to put the html in
	outputString = [[NSMutableString alloc] init];
	
	//Append a header
	[self header];
	
	//Find out if managedObject is an ObjCAbstractMethodContainer
	NSEntityDescription *ObjCAbstractMethodContainer = [NSEntityDescription entityForName:@"ObjCAbstractMethodContainer" inManagedObjectContext:transientContext];
	NSEntityDescription *ObjCMethod = [NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:transientContext];
	if ([[transientObject entity] isKindOfEntity:ObjCAbstractMethodContainer])
	{
		//Append the main content
		if (displayType == IGKHTMLDisplayType_All)
			[self html_all];
		else if (displayType == IGKHTMLDisplayType_Overview)
			[self html_overview];
		else if (displayType == IGKHTMLDisplayType_Tasks)
			[self html_tasks];
		else if (displayType == IGKHTMLDisplayType_Properties)
			[self html_properties];
		else if (displayType == IGKHTMLDisplayType_Methods)
			[self html_methods];
		else if (displayType == IGKHTMLDisplayType_Notifications)
			[self html_notifications];
		else if (displayType == IGKHTMLDisplayType_Delegate)
			[self html_delegate];
	}
	else if ([[transientObject entity] isKindOfEntity:ObjCMethod])
	{
		[outputString appendString:@"<div id='methods' class='single'>"];
		
		[self html_method:transientObject];
		
		[outputString appendString:@"</div>"];
	}
	
	//Append a footer
	[self footer];
		
	return outputString;
}
- (void)html_all
{	
	[self html_overview];
	[self html_tasks];
	[self html_properties];
	[self html_methods];
	[self html_notifications];
	[self html_delegate];
}
- (void)html_overview
{
	[outputString appendString:@"<div id='overview'>"];
	
	[outputString appendFormat:@"<h1>%@</h1>", [self escape:[transientObject valueForKey:@"name"]]];
	
	if ([transientObject valueForKey:@"overview"])
		[outputString appendString:[transientObject valueForKey:@"overview"]];	
	
	[outputString appendString:@"</div>"];
}
- (void)html_tasks
{
	
}
- (void)html_properties
{
	
}
- (void)html_methods
{	
	[outputString appendString:@"<div id='methods'>"];
	
	NSFetchRequest *methodsFetch = [[NSFetchRequest alloc] init];
	[methodsFetch setEntity:[NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:transientContext]];
	[methodsFetch setPredicate:[NSPredicate predicateWithFormat:@"container=%@", transientObject]];
	[methodsFetch setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	
	NSError *error = nil;
	NSArray *methods = [transientContext executeFetchRequest:methodsFetch error:&error];
	for (IGKDocRecordManagedObject *object in methods)
	{
		[self html_method:object];
	}
	
	[outputString appendString:@"</div>"];
}
- (void)html_notifications
{
	
}
- (void)html_delegate
{
	
}

- (void)html_method:(IGKDocRecordManagedObject *)object
{
	[outputString appendFormat:@"\t<div class='method'>\n"];
	
	if ([object valueForKey:@"name"])
		[outputString appendFormat:@"\t\t<h2>%@</h2>\n", [self escape:[object valueForKey:@"name"]]];
	
	if ([object valueForKey:@"overview"])
		[outputString appendFormat:@"\t\t<div class='description'>%@</div>\n", [object valueForKey:@"overview"]];
	
	if ([object valueForKey:@"signature"])
		[outputString appendFormat:@"\t\t<p class='prototype'><code>%@</code></p>\n", [object valueForKey:@"signature"]];
	
	BOOL hasParameters = [[object valueForKey:@"parameters"] count];
	BOOL hasReturnDescription = [object valueForKey:@"returnDescription"] ? YES : NO;
	if (hasParameters || hasReturnDescription)
	{
		[outputString appendString:@"\t\t<div class='in-out-vals'>\n"];
		
		if (hasParameters)
		{
			for (NSManagedObject *parameter in [object valueForKey:@"parameters"])
			{
				[outputString appendFormat:@"\t\t\t<p class='parameter'><strong>%@</strong> %@</p>\n", [parameter valueForKey:@"name"], [parameter valueForKey:@"overview"]];
			}
		}
		
		if (hasReturnDescription)
		{
			[outputString appendFormat:@"\t\t\t<p class='returns'><strong>Returns</strong> %@</p>\n", [object valueForKey:@"returnDescription"]];
		}
		
		[outputString appendString:@"\t\t</div>\n"];
	}
	
	if ([object valueForKey:@"availability"])
	{
		[outputString appendString:@"\t\t<div class='info availability'>\n"];
		
		[outputString appendString:@"\t\t\t<h3>Availability</h3>\n"];
		[outputString appendFormat:@"\t\t\t<p>%@</p>\n", [object valueForKey:@"availability"]];
		
		[outputString appendString:@"\t\t</div>\n"];
	}
	
	if ([object valueForKey:@"declared_in_header"])
	{
		[outputString appendString:@"\t\t<div class='info declared_in_header'>\n"];
		
		[outputString appendString:@"\t\t\t<h3>Declared In</h3>\n"];
		[outputString appendFormat:@"\t\t\t<p>%@</p>\n", [object valueForKey:@"declared_in_header"]];
		
		[outputString appendString:@"\t\t</div>\n"];
	}
	
	if ([[object valueForKey:@"seealsos"] count])
	{
		[outputString appendFormat:@"\t\t<div class='seealso'>\n"];
		[outputString appendFormat:@"\t\t\t<strong>See Also</strong>\n"];
		[outputString appendFormat:@"\t\t\t<ul>\n"];
		
		NSSet *seealsos = [object valueForKey:@"seealsos"];
		
		//Sort by name
		NSSortDescriptor *nameSorter = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
		NSArray *sortedSeealsos = [[seealsos allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameSorter]];
		
		for (NSManagedObject *seealso in sortedSeealsos)
		{
			[outputString appendFormat:@"\t\t\t\t<li><code><a href='#' class='stealth'>%@</a></code></li>\n", [seealso valueForKey:@"name"]];
		}
		
		[outputString appendFormat:@"\t\t\t</ul>\n"];
		[outputString appendFormat:@"\t\t</div>\n"];
	}
	
	if ([[object valueForKey:@"samplecodeprojects"] count])
	{
		[outputString appendFormat:@"\t\t<div class='seealso'>\n"];
		[outputString appendFormat:@"\t\t\t<strong>Sample Code</strong>\n"];
		[outputString appendFormat:@"\t\t\t<ul>\n"];
		
		NSSet *seealsos = [object valueForKey:@"samplecodeprojects"];
		
		//Sort by name
		NSSortDescriptor *nameSorter = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
		NSArray *sortedSeealsos = [[seealsos allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameSorter]];
		
		for (NSManagedObject *seealso in sortedSeealsos)
		{
			[outputString appendFormat:@"\t\t\t\t<li><code><a href='#' class='stealth'>%@</a></code></li>\n", [seealso valueForKey:@"name"]];
		}
		
		[outputString appendFormat:@"\t\t\t</ul>\n"];
		[outputString appendFormat:@"\t\t</div>\n"];
	}
	
	[outputString appendFormat:@"\t</div>\n\n"];
}

@end
