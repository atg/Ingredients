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

- (NSString *)header;
- (NSString *)footer;

- (NSString *)html_all;
- (NSString *)html_overview;
- (NSString *)html_tasks;
- (NSString *)html_properties;
- (NSString *)html_methods;
- (NSString *)html_notifications;
- (NSString *)html_delegate;

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

- (NSString *)header
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	[outputString appendFormat:@"<!doctype html>\n<html>\n<head>\n<meta charset='utf-8'>\n<title>%@</title>\n<link rel='stylesheet' href='main.css' type='text/css' media='screen'>\n</head>\n<body>\n", [transientObject valueForKey:@"name"]];
	
	return outputString;
}
- (NSString *)footer
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	[outputString appendString:@"</body>\n</html>\n"];
	
	return outputString;
}	 

- (NSString *)html
{
	if (!managedObject)
		return @"";
	
	//Do a full scrape of the documentation referenced by managedObject
	IGKFullScraper *fullScraper = [[IGKFullScraper alloc] initWithManagedObject:managedObject];
	[fullScraper start];
	
	transientContext = fullScraper.transientContext;
	transientObject = fullScraper.transientObject;
	
	
	//Find out if managedObject is an ObjCAbstractMethodContainer
	NSEntityDescription *ObjCAbstractMethodContainer = [NSEntityDescription entityForName:@"ObjCAbstractMethodContainer" inManagedObjectContext:transientContext];
	isMethodContainer = [[transientObject entity] isKindOfEntity:ObjCAbstractMethodContainer];
	
	//Create a string to put the html in
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	//Append a header
	[outputString appendString:[self header]];
	
	//Append the main content
	if (displayType == IGKHTMLDisplayType_All)
		[outputString appendString:[self html_all]];
	else if (displayType == IGKHTMLDisplayType_Overview)
		[outputString appendString:[self html_overview]];
	else if (displayType == IGKHTMLDisplayType_Tasks)
		[outputString appendString:[self html_tasks]];
	else if (displayType == IGKHTMLDisplayType_Properties)
		[outputString appendString:[self html_properties]];
	else if (displayType == IGKHTMLDisplayType_Methods)
		[outputString appendString:[self html_methods]];
	else if (displayType == IGKHTMLDisplayType_Notifications)
		[outputString appendString:[self html_notifications]];
	else if (displayType == IGKHTMLDisplayType_Delegate)
		[outputString appendString:[self html_delegate]];
	
	//Append a footer
	[outputString appendString:[self footer]];
	
	[fullScraper cleanUp];
	
	return outputString;
}
- (NSString *)html_all
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	[outputString appendString:[self html_overview]];
	[outputString appendString:[self html_tasks]];
	[outputString appendString:[self html_properties]];
	[outputString appendString:[self html_methods]];
	[outputString appendString:[self html_notifications]];
	[outputString appendString:[self html_delegate]];
	
	return outputString;
}
- (NSString *)html_overview
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	[outputString appendString:@"<div id='overview'>"];
	
	[outputString appendFormat:@"<h1>%@</h1>", [self escape:[transientObject valueForKey:@"name"]]];
	
	if ([transientObject valueForKey:@"overview"])
		[outputString appendString:[transientObject valueForKey:@"overview"]];	
	
	[outputString appendString:@"</div>"];
	return outputString;
}
- (NSString *)html_tasks
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	return outputString;
}
- (NSString *)html_properties
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	return outputString;
}
- (NSString *)html_methods
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	[outputString appendString:@"<div id='methods'>"];
	
	NSFetchRequest *methodsFetch = [[NSFetchRequest alloc] init];
	[methodsFetch setEntity:[NSEntityDescription entityForName:@"ObjCMethod" inManagedObjectContext:transientContext]];
	[methodsFetch setPredicate:[NSPredicate predicateWithFormat:@"container=%@", transientObject]];
	[methodsFetch setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	
	NSError *error = nil;
	NSArray *methods = [transientContext executeFetchRequest:methodsFetch error:&error];
	for (NSManagedObject *object in methods)
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
	
	[outputString appendString:@"</div>"];
	
	NSLog(@"outputString = %@", outputString);
	
	return outputString;
}
- (NSString *)html_notifications
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	return outputString;
}
- (NSString *)html_delegate
{
	NSMutableString *outputString = [[NSMutableString alloc] init];
	
	return outputString;
}

@end
