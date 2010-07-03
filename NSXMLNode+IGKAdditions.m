//
//  NSXMLNode+IGKAdditions.m
//  Ingredients
//
//  Created by Alex Gordon on 05/03/2010.
//  Written in 2010 by Fileability.
//

#import "NSXMLNode+IGKAdditions.h"


void IGKPutChildrenMatchingPredicateIntoArray(NSXMLElement *element, BOOL (^predicate)(NSXMLNode*), NSMutableArray *elements)
{
	if (![element isKindOfClass:[NSXMLElement class]])
		return;
	
	//If the node matches the predicate, add it to the array
	if (predicate(element))
		[elements addObject:element];
	
	for (NSXMLNode *node in [element children])
	{
		//Recursively put any matching children of node into the nodes array
		IGKPutChildrenMatchingPredicateIntoArray(node, predicate, elements);
	}
}

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

- (NSArray *)nodesMatchingPredicate:(BOOL (^)(NSXMLNode*))predicate
{
	NSMutableArray *nodes = [[NSMutableArray alloc] initWithCapacity:50];
	
	IGKPutChildrenMatchingPredicateIntoArray((NSXMLElement *)self, predicate, nodes);
	
	return nodes;
}

- (NSString *)attributeForLocalName:(NSString *)str
{
	return [self attributeForLocalName:str URI:nil];
}

@end
