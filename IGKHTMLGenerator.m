//
//  IGKHTMLGenerator.m
//  Ingredients
//
//  Created by Alex Gordon on 26/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "IGKHTMLGenerator.h"


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
	
	[outputString appendString:@"<!doctype html>\n<html>\n<head>\n<meta charset='utf-8'>\n<title>%@</title>\n<link rel='stylesheet' href='main.css' type='text/css' media='screen'>\n</head>\n<body>\n"];
	
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
	//Find out if managedObject is an ObjCAbstractMethodContainer
	NSEntityDescription *ObjCAbstractMethodContainer = [NSEntityDescription entityForName:@"ObjCAbstractMethodContainer" inManagedObjectContext:context];
	isMethodContainer = [[managedObject entity] isKindOfEntity:ObjCAbstractMethodContainer];
	
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
	
	[outputString appendFormat:@"<h1>%@</h1>", [self escape:[managedObject valueForKey:@"name"]]];
	[outputString appendString:[managedObject valueForKey:@"overview"]];	
	
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
	
	[outputString appendString:@"METHODS"];
	
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
