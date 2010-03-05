//
//  NSXMLNode+IGKAdditions.m
//  Ingredients
//
//  Created by Alex Gordon on 05/03/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import "NSXMLNode+IGKAdditions.h"


@implementation NSXMLNode (IGKAdditions)

- (NSString *)commentlessStringValue
{	
	if ([self kind] == NSXMLElementKind)
	{
		NSMutableString *str = [[NSMutableString alloc] init];
		
		[self innerCommentlessStringValueInto:str];
		
		return str;
	}
	
	return [self stringValue];
}
- (void)innerCommentlessStringValueInto:(NSMutableString *)str
{
	NSXMLNodeKind kind = [self kind];
	
	if (kind == NSXMLTextKind)
	{
		[str appendString:[self stringValue]];
	}
	else
	{
		for (NSXMLNode *n in [self children])
		{
			[n innerCommentlessStringValueInto:str];
		}
	}
}

@end
