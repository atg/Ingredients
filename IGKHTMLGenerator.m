//
//  IGKHTMLGenerator.m
//  Ingredients
//
//  Created by Alex Gordon on 26/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKHTMLGenerator.h"
#import "IGKScraper.h"
#import "IGKDocRecordManagedObject.h"
#import "RegexKitLite.h"

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

- (void)html_methodLikeDeclarationsWithEntity:(NSString *)entityName hasParameters:(BOOL)hasParameters;
- (void)html_method:(IGKDocRecordManagedObject *)obj hasParameters:(BOOL)hasParameters;
- (void)html_metadataTable:(IGKDocRecordManagedObject *)object;
- (void)html_parametersForCallable:(IGKDocRecordManagedObject *)object;

- (void)html_generic;

- (NSString *)hrefToActualFragment:(IGKDocRecordManagedObject *)mo;

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
		if ([[transientObject valueForKey:@"overview"] length] || [[transientObject valueForKey:@"taskgroups"] count])
			mask |= IGKHTMLDisplayType_Overview;
		if ([[transientObject valueForKey:@"properties"] count])
			mask |= IGKHTMLDisplayType_Properties;
		if ([[transientObject valueForKey:@"methods"] count])
			mask |= IGKHTMLDisplayType_Methods;
		//if ([[transientObject valueForKey:@"miscitems"] count])
		//	mask |= IGKHTMLDisplayType_Misc;
		
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
		[outputString appendString:@"<div class='methods' class='single'>\n"];
		
		[self html_method:transientObject hasParameters:YES];
		
		[outputString appendString:@"</div>\n"];
	}
	else
	{
		[self html_generic];
	}
	
	//Append a footer
	[self footer];
		
	return outputString;
}
- (void)html_all
{	
	[self html_overview];
	[self html_properties];
	[self html_methods];
	[self html_notifications];
	[self html_delegate];
}
- (void)html_overview
{
	[outputString appendString:@"<a name='overview'></a>\n"];
	[outputString appendString:@"<div class='methods overview'>\n"];
	
	[outputString appendFormat:@"<h1>%@</h1>", [self escape:[transientObject valueForKey:@"name"]]];
	
	if ([transientObject valueForKey:@"overview"])
		[outputString appendString:[transientObject valueForKey:@"overview"]];	
	
	[self html_metadataTable:transientObject];
	
	[outputString appendString:@"</div>\n"];
	
	[self html_tasks];
}
- (void)html_tasks
{
	[outputString appendString:@"<a name='tasks'></a>\n"];
	[outputString appendString:@"<div class='methods tasks'>\n"];
	
	NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"positionIndex" ascending:YES];
	NSArray *taskgroups = [[[transientObject valueForKey:@"taskgroups"] allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	for (NSManagedObject *taskgroup in taskgroups)
	{
		[outputString appendFormat:@"<h2>%@</h2>\n", [taskgroup valueForKey:@"name"]];
		[outputString appendString:@"<ul>\n"];
		
		NSArray *taskgroupItems = [[[taskgroup valueForKey:@"items"] allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
		for (IGKDocRecordManagedObject *taskgroupItem in taskgroupItems)
		{
			NSString *hrefAndNameAndType = [self hrefToActualFragment:taskgroupItem];
			
			[outputString appendFormat:@"<li><code><a href='%@' class='stealth'>%@</a></code></li>\n", hrefAndNameAndType, [taskgroupItem valueForKey:@"name"]];
		}
		
		[outputString appendString:@"</ul>\n"];
	}
	
	[outputString appendString:@"</div>\n"];
}
- (NSString *)hrefToActualFragment:(IGKDocRecordManagedObject *)mo
{
	NSString *href = [mo valueForKey:@"href"];
		
	// NSString.html#//apple_ref/occ/instm/NSString/stringByAppendingPathComponent:
	// We need to grab
	//   the type (cl, instm, etc)
	//   the container (NSString)
	//   the item (stringByAppendingPathComponent:)
	
	NSString *regex = @"//apple_ref/(occ|c)/([^/]+)/([^/]+)(/([^/]+))?";
	NSArray *captures = [href captureComponentsMatchedByRegex:regex];
	if ([captures count] < 4)
		return nil;
	
	NSString *applecode = [captures objectAtIndex:2];
	NSString *n = [captures objectAtIndex:3];
	
	NSString *containerName = nil;
	NSString *itemName = nil;
	
	
	if ([captures count] >= 6)
	{
		containerName = n;
		itemName = [captures objectAtIndex:5];
	}
	else
	{
		itemName = n;
	}
	
	NSString *ingrcode = nil;
	if ([applecode isEqual:@"cl"])
		ingrcode = @"class";
	else if ([applecode isEqual:@"cat"])
		ingrcode = @"category";
	else if ([applecode isEqual:@"intf"])
		ingrcode = @"protocol";
	else if ([applecode isEqual:@"instm"] || [applecode isEqual:@"intfm"])
		ingrcode = @"instance-method";
	else if ([applecode isEqual:@"clm"] || [applecode isEqual:@"intfcm"])
		ingrcode = @"class-method";
	else if ([applecode isEqual:@"intfp"] || [applecode isEqual:@"instp"])
		ingrcode = @"property";
	else if ([applecode isEqual:@"tdef"])
		ingrcode = @"type";
	else if ([applecode isEqual:@"func"])
		ingrcode = @"function";
	else if ([applecode isEqual:@"econst"] || [applecode isEqual:@"data"] || [applecode isEqual:@"tag"])
	{
		if ([applecode isEqual:@"data"] && [itemName isLike:@"*Notification"])
			ingrcode = @"notification";
		else
			ingrcode = @"constant";
	}
	else if ([applecode isEqual:@"constant_group"])
	{
		ingrcode = @"global";
	}
	
	if ([containerName isEqual:[transientObject valueForKey:@"name"]] || [itemName isEqual:[transientObject valueForKey:@"name"]])
	{
		BOOL containsInDocument = NO;
		if (displayTypeMask & IGKHTMLDisplayType_All)
			containsInDocument = YES;
		
		else if ([ingrcode isEqual:@"instance-method"] || [ingrcode isEqual:@"class-method"])
			containsInDocument = (displayTypeMask & IGKHTMLDisplayType_Methods);
		
		else if ([ingrcode isEqual:@"property"])
			containsInDocument = (displayTypeMask & IGKHTMLDisplayType_Properties);
		
		else if ([ingrcode isEqual:@"notification"])
			containsInDocument = (displayTypeMask & IGKHTMLDisplayType_Notifications);
		
		else
			containsInDocument = (displayTypeMask & IGKHTMLDisplayType_Misc);
		
		if (containsInDocument)
			return [NSString stringWithFormat:@"#%@.%@", itemName, ingrcode];
	}
	
	NSString *url = nil;
	if (containerName)
	{
		//FIXME: This assumes that transientObject is the container: [transientObject URLComponentExtension]. It won't work if the link is to another class
		url = [NSString stringWithFormat:@"http://ingr-doc/%@/all/%@.%@/%@.%@", [[transientObject valueForKey:@"Docset"] docsetURLHost], containerName, [transientObject URLComponentExtension], itemName, ingrcode];
	}
	else
	{
		url = [NSString stringWithFormat:@"http://ingr-doc/%@/all/%@.%@", [[transientObject valueForKey:@"Docset"] docsetURLHost], itemName, ingrcode];
	}
	
	return url;
}
- (void)html_properties
{
	[outputString appendString:@"<a name='properties'></a>\n"];
	[outputString appendString:@"<div class='methods' class='properties'>\n"];
	
	[self html_methodLikeDeclarationsWithEntity:@"ObjCProperty" hasParameters:NO];
	
	[outputString appendString:@"</div>"];
}
- (void)html_methods
{	
	[outputString appendString:@"<a name='methods'></a>\n"];
	[outputString appendString:@"<div class='methods'>\n"];
	
	[self html_methodLikeDeclarationsWithEntity:@"ObjCMethod" hasParameters:YES];
	
	[outputString appendString:@"</div>\n"];
}
- (void)html_methodLikeDeclarationsWithEntity:(NSString *)entityName hasParameters:(BOOL)hasParameters
{
	NSFetchRequest *methodsFetch = [[NSFetchRequest alloc] init];
	[methodsFetch setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:transientContext]];
	[methodsFetch setPredicate:[NSPredicate predicateWithFormat:@"container=%@", transientObject]];
	[methodsFetch setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	
	NSError *error = nil;
	NSArray *methods = [transientContext executeFetchRequest:methodsFetch error:&error];
	for (IGKDocRecordManagedObject *object in methods)
	{
		[self html_method:object hasParameters:hasParameters];
	}
}

- (void)html_notifications
{
	[outputString appendString:@"<a name='notifications'></a>\n"];
	[outputString appendString:@"<div class='methods' class='notifications'>\n"];
	
	[self html_methodLikeDeclarationsWithEntity:@"ObjCNotification" hasParameters:NO];
	
	[outputString appendString:@"</div>\n"];
}
- (void)html_delegate
{
	
}

- (void)html_method:(IGKDocRecordManagedObject *)object hasParameters:(BOOL)hasParameters
{
	[outputString appendFormat:@"<a name='%@.%@'></a>\n", [object valueForKey:@"name"], [object URLComponentExtension]];
	[outputString appendFormat:@"\t<div class='method'>\n"];
	
	if ([object valueForKey:@"name"])
		[outputString appendFormat:@"\t\t<h2>%@</h2>\n", [self escape:[object valueForKey:@"name"]]];
	
	BOOL isnotif = [object isKindOfEntityNamed:@"ObjCNotification"];
	
	if ([object valueForKey:@"overview"])
		[outputString appendFormat:@"\t\t<div class='description'>%@</div>\n", [object valueForKey:@"overview"]];
	
	if ([object valueForKey:@"signature"])
		[outputString appendFormat:@"\t\t<p class='prototype'><code>%@</code></p>\n", [object valueForKey:@"signature"]];
	
	if (hasParameters)
		[self html_parametersForCallable:object];
	
	if ([object valueForKey:@"discussion"])
		[outputString appendFormat:@"\t\t<hr>\n\n\t\t<div class='discussion'>%@</div>\n\n\t\t<hr>\n\n", [object valueForKey:@"discussion"]];
	
	[self html_metadataTable:object];
	
	[outputString appendFormat:@"\t</div>\n\n"];
}
- (void)html_parametersForCallable:(IGKDocRecordManagedObject *)object
{
	BOOL hasParameters = [[object valueForKey:@"parameters"] count];
	BOOL hasReturnDescription = [object valueForKey:@"returnDescription"] ? YES : NO;
	if (hasParameters || hasReturnDescription)
	{
		[outputString appendString:@"\t\t<div class='in-out-vals'>\n"];
		
		if (hasParameters)
		{
			NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"positionIndex" ascending:YES];
			NSArray *parameters = [[[object valueForKey:@"parameters"] allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
			for (NSManagedObject *parameter in parameters)
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
}
- (void)html_metadataTable:(IGKDocRecordManagedObject *)object
{
	if ([object valueForKey:@"specialConsiderations"])
	{
		[outputString appendString:@"\t\t<div class='info special_considerations'>\n"];
		
		[outputString appendString:@"\t\t\t<h3>Special Considerations</h3>\n"];
		[outputString appendFormat:@"\t\t\t<p>%@</p>\n", [object valueForKey:@"specialConsiderations"]];
		
		[outputString appendString:@"\t\t</div>\n"];
	}
	
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
	
	if ([object valueForKey:@"conformsto"] || [object valueForKey:@"superclass"])
		maxrowcount = 1;
	
	maxrowcount = MAX(maxrowcount, [[object valueForKey:@"seealsos"] count]);
	
	maxrowcount = MAX(maxrowcount, [[object valueForKey:@"samplecodeprojects"] count]);
	
	//If there's rows to be rendered, then add a table element
	if (maxrowcount > 0)
		[outputString appendString:@"\t\t<table class='info'>\n"];
	
	NSUInteger i = 0;
	
	NSArray *seealsos = [[[object valueForKey:@"seealsos"] allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	//NSArray *seealsos = [[ valueForKey:@"name"] sortedArrayUsingSelector:@selector(localizedCompare:)];
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
				{	
					NSString *declaredIn = [object valueForKey:@"declared_in_header"];
					NSString *declaredInURL = [NSString stringWithFormat:@"http://ingr-doc/%@/all/%@.%@", [[transientObject valueForKey:@"Docset"] docsetURLHost], declaredIn, @"headerfile"];

					[outputString appendFormat:@"\t\t\t\t<td rowspan='%d'><code><a href='%@' class='stealth'>%@</a></code></td>\n", maxrowcount, declaredInURL, declaredIn];
				}
			}
			
			if ([object valueForKey:@"superclass"])
			{
				if (i == 0)
					[outputString appendString:@"\t\t\t\t<th>Superclass</th>\n"];
				else
				{
					NSString *superclass = [object valueForKey:@"superclass"];
					NSString *superclassURL = [NSString stringWithFormat:@"http://ingr-doc/%@/all/%@.%@", [[transientObject valueForKey:@"Docset"] docsetURLHost], superclass, @"class"];
					[outputString appendFormat:@"\t\t\t\t<td rowspan='%d'><code><a href='%@' class='stealth'>%@</a></code></td>\n", maxrowcount, superclassURL, superclass];
				}
			}
			
			if ([object valueForKey:@"conformsto"])
			{
				if (i == 0)
					[outputString appendString:@"\t\t\t\t<th>Conforms to</th>\n"];
				else
				{
					NSString *conformstoOmnibus = [object valueForKey:@"conformsto"];
					conformstoOmnibus = [conformstoOmnibus stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
					
					NSArray *conformstoProtocols = [conformstoOmnibus componentsSeparatedByString:@"="];
					[outputString appendFormat:@"\t\t\t\t<td rowspan='%d'>", maxrowcount];
					
					for (NSString *conformstoProtocol in conformstoProtocols)
					{
						NSString *conformstoURL = [NSString stringWithFormat:@"http://ingr-doc/%@/all/%@.%@", [[transientObject valueForKey:@"Docset"] docsetURLHost], conformstoProtocol, @"protocol"];
						[outputString appendFormat:@"<code><a href='%@' class='stealth'>%@</a></code><br>\n", conformstoURL, conformstoProtocol];
					}
					
					[outputString appendString:@"</td>\n"];
				}
			}
		}
		
		//See also
		if (i == 0 && [seealsos count])
			[outputString appendString:@"\t\t\t\t<th>See also</th>\n"];
		else if (i > 0 && i - 1 < [seealsos count])
		{
			IGKDocRecordManagedObject *mo = [seealsos objectAtIndex:i - 1];
			[outputString appendFormat:@"\t\t\t\t<td><code><a href='%@' class='stealth'>%@</a></code></td>\n", [self hrefToActualFragment:mo], [mo valueForKey:@"name"]];
		}
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
}


- (void)html_generic
{
	[outputString appendString:@"<div class='#overview'>"];
	[outputString appendString:@"<div class='overview'>"];
	
	[outputString appendFormat:@"<h1>%@</h1>", [self escape:[transientObject valueForKey:@"name"]]];
	
	if ([transientObject valueForKey:@"discussion"])
		[outputString appendString:[transientObject valueForKey:@"discussion"]];
	else if ([transientObject valueForKey:@"overview"])
		[outputString appendString:[transientObject valueForKey:@"overview"]];
	
	
	[outputString appendString:@"<div class='methods'>"];
	
	if ([transientObject valueForKey:@"signature"])
		[outputString appendFormat:@"\t\t<p class='prototype'><code>%@</code></p>\n", [transientObject valueForKey:@"signature"]];
	
	if ([transientObject isKindOfEntityNamed:@"Callable"])
		[self html_parametersForCallable:transientObject];
	
	[self html_metadataTable:transientObject];
	
	[outputString appendString:@"</div>"];
	
	
	[outputString appendString:@"</div>"];
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
