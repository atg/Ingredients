//
//  IGKHTMLGenerator.m
//  Ingredients
//
//  Created by Alex Gordon on 26/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKHTMLGenerator.h"
#import "IGKScraper.h"

BOOL IGKHTMLDisplayTypeMaskIsSingle(IGKHTMLDisplayTypeMask mask)
{
	return mask == 0 || (mask & (mask - 1)) == 0;
}

@interface IGKHTMLGenerator ()

- (NSString *)escape:(NSString *)unescapedText;
- (NSString *)processAvailability:(NSString *)availability;

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
@synthesize displayTypeMask;

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
	
	managedObject = mo;
	
	//Do a full scrape of the documentation referenced by managedObject
	fullScraper = [[IGKFullScraper alloc] initWithManagedObject:managedObject];
	[fullScraper start];
	
	transientContext = fullScraper.transientContext;
	transientObject = (IGKDocRecordManagedObject *)(fullScraper.transientObject);
}
- (void)finalize
{
	[fullScraper cleanUp];
	fullScraper = nil;
	
	[super finalize];
}

- (IGKHTMLDisplayTypeMask)acceptableDisplayTypes
{
	IGKHTMLDisplayTypeMask mask = IGKHTMLDisplayType_All;
	
	NSEntityDescription *entity = [transientObject entity];
	if ([entity isKindOfEntity:[NSEntityDescription entityForName:@"ObjCClass" inManagedObjectContext:transientContext]])
	{
		if ([[transientObject valueForKey:@"overview"] length])
			mask |= IGKHTMLDisplayType_Overview;
		if ([[transientObject valueForKey:@"taskgroups"] count])
			mask |= IGKHTMLDisplayType_Tasks;
		if ([[transientObject valueForKey:@"properties"] count])
			mask |= IGKHTMLDisplayType_Properties;
		if ([[transientObject valueForKey:@"methods"] count])
			mask |= IGKHTMLDisplayType_Methods;
		if ([[transientObject valueForKey:@"miscitems"] count])
			mask |= IGKHTMLDisplayType_Misc;
		if ([[transientObject valueForKey:@"notifications"] count])
			mask |= IGKHTMLDisplayType_Notifications;
		if ([[transientObject valueForKey:@"delegatemethods"] count])
			mask |= IGKHTMLDisplayType_Delegate;
		
		if ([entity isKindOfEntity:[NSEntityDescription entityForName:@"ObjCClass" inManagedObjectContext:transientContext]])
		{
			if ([[transientObject valueForKey:@"bindinglistings"] count])
				mask |= IGKHTMLDisplayType_BindingListings;
		}
	}
	
	return mask;
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
		if (displayTypeMask & IGKHTMLDisplayType_All)
			[self html_all];
		else
		{
			if (displayTypeMask & IGKHTMLDisplayType_Overview)
				[self html_overview];
			if (displayTypeMask & IGKHTMLDisplayType_Tasks)
				[self html_tasks];
			if (displayTypeMask & IGKHTMLDisplayType_Properties)
				[self html_properties];
			if (displayTypeMask & IGKHTMLDisplayType_Methods)
				[self html_methods];
			if (displayTypeMask & IGKHTMLDisplayType_Notifications)
				[self html_notifications];
			if (displayTypeMask & IGKHTMLDisplayType_Delegate)
				[self html_delegate];
		}
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
	
	if ([object valueForKey:@"discussion"])
		[outputString appendFormat:@"\t\t<hr>\n\n\t\t<div class='discussion'>%@</div>\n\n\t\t<hr>\n\n", [object valueForKey:@"discussion"]];
	
	//Create a table for the various metadata. Now it gets tricky
	//We want to generate something like
	/* 
		<table class="info">
			    <tr>
			        <th>Available in</th>
			        <th>Declared in</th>
			        <th>See also</th>
			        <th>Sample code</th>
			    </tr>
			    <tr class="first">
			        <td rowspan="3">OS X <strong>10.4</strong>+</td>
			        <td rowspan="3"><code>NSString.h</code></td>
			        <td><code><a href="#" class="stealth">- cStringUsingEncoding:</a></code></td>
			        <td><code><a href="#" class="stealth">QTMetadataEditor</a></code></td>
			    </tr>
			    <tr>
			        <td><code><a href="#" class="stealth">- canBeConvertedToEncoding:</a></code></td>
			        <td></td>
			    </tr>
			    <tr class="last">
			        <td><code><a href="#" class="stealth">- UTF8String</a></code></td>
			        <td></td>
			    </tr>
			    
			</table>
	 */
	
	/*
	 In particular, columns that only ever show one piece of data (such as availability) should have a rowspan = the total number of data rows. They should only generate elements in the first row
	 meanwhile, rows that may show more than one piece of data (such as seealsos) should have no rowspan. They should generate empty <td> elements when they run out of data
	 */
	
	//Find the total number of rows
	NSUInteger maxrowcount = 0;
	
	//If we have availability or declared_in_header, then we have at least one row
	if ([object valueForKey:@"availability"] || [object valueForKey:@"declared_in_header"])
		maxrowcount = 1;
	
	if ([[object valueForKey:@"seealsos"] count])
		maxrowcount = [[object valueForKey:@"seealsos"] count];
	
	if ([[object valueForKey:@"samplecodeprojects"] count] > maxrowcount)
		maxrowcount = [[object valueForKey:@"samplecodeprojects"] count];
	
	//If there's rows to be rendered, then add a table element
	if (maxrowcount > 0)
		[outputString appendString:@"\t\t<table class='info'>\n"];
	
	NSUInteger i = 0;
	
	NSArray *seealsos = [[[[object valueForKey:@"seealsos"] allObjects] valueForKey:@"name"] sortedArrayUsingSelector:@selector(localizedCompare:)];
	NSArray *samplecodeprojects = [[[[object valueForKey:@"samplecodeprojects"] allObjects] valueForKey:@"name"] sortedArrayUsingSelector:@selector(localizedCompare:)];
	
	for (i = 0; i < maxrowcount + 1; i++)
	{
		// <tr>
		if (i == 1)
			[outputString appendString:@"\t\t\t<tr class='first'>\n"];
		else
			[outputString appendString:@"\t\t\t<tr>\n"];
		
		if (i == 0 || i == 1)
		{
			if ([object valueForKey:@"availability"])
			{
				if (i == 0)
					[outputString appendString:@"\t\t\t\t<th>Available in</th>\n"];
				else
					[outputString appendFormat:@"\t\t\t\t<td rowspan='%d'>%@</td>\n", maxrowcount, [self processAvailability:[object valueForKey:@"availability"]]];
			}
			
			if ([object valueForKey:@"declared_in_header"])
			{
				if (i == 0)
					[outputString appendString:@"\t\t\t\t<th>Declared in</th>\n"];
				else
					[outputString appendFormat:@"\t\t\t\t<td rowspan='%d'><code><a href='#' class='stealth'>%@</a></code></td>\n", maxrowcount, [object valueForKey:@"declared_in_header"]];
			}
		}
		
		//See also
		if (i == 0 && [seealsos count])
			[outputString appendString:@"\t\t\t\t<th>See also</th>\n"];
		else if (i > 0 && i - 1 < [seealsos count])
			[outputString appendFormat:@"\t\t\t\t<td><code><a href='#' class='stealth'>%@</a></code></td>\n", [seealsos objectAtIndex:i - 1]];
		else if ([seealsos count])
			[outputString appendString:@"\t\t\t\t<td></td>\n"];
		
		//See also
		if (i == 0 && [samplecodeprojects count])
			[outputString appendString:@"\t\t\t\t<th>Sample projects</th>\n"];
		else if (i > 0 && i - 1 < [samplecodeprojects count])
			[outputString appendFormat:@"\t\t\t\t<td><code><a href='#' class='stealth'>%@</a></code></td>\n", [samplecodeprojects objectAtIndex:i - 1]];
		else if ([samplecodeprojects count])
			[outputString appendString:@"\t\t\t\t<td></td>\n"];
		
		[outputString appendString:@"\t\t\t</tr>\n"];
	}
	
	if (maxrowcount > 0)
		[outputString appendString:@"\t\t</table>\n"];
		
#if 0
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
#endif
	
	[outputString appendFormat:@"\t</div>\n\n"];
}

- (NSString *)processAvailability:(NSString *)availability
{
	NSMutableString *str = [availability mutableCopy];
	
	//Delete "Available in "
	[str replaceOccurrencesOfString:@"Available in " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
	
	//Delete " and later."
	[str replaceOccurrencesOfString:@" and later." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
	
	//Replace "Mac OS X v" with "Mac OS X <strong>"
	if ([str replaceOccurrencesOfString:@"Mac OS X v" withString:@"Mac OS X <strong>" options:NSLiteralSearch range:NSMakeRange(0, [str length])])
	{
		
	}
	//or "iPhone OS " with "iPhone OS <strong>"
	else if ([str replaceOccurrencesOfString:@"iPhone OS " withString:@"iPhone OS <strong>" options:NSLiteralSearch range:NSMakeRange(0, [str length])])
	{
		
	}
	//or else we have no clue - just make it all bold
	else
	{
		[str insertString:@"<strong>" atIndex:0];
	}
	
	//Append a "<strong>+"
	[str appendString:@"</strong>+"];
	
	return str;
}

@end
