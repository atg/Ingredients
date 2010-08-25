//
//  IGKPredicateEditor.m
//  Ingredients
//
//  Created by Alex Gordon on 23/03/2010.
//  Written in 2010 by Fileability.
//

#import "IGKPredicateEditor.h"


@implementation IGKPredicateEditor

- (NSPredicate *)predicate
{
	//We want to remove any null comparison predicates from our predicate
	NSCompoundPredicate *predicate = (NSCompoundPredicate *)[super predicate];
	
	if (!predicate)
		return nil;
	
	if ([predicate isKindOfClass:[NSComparisonPredicate class]])
	{
		predicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:[NSArray arrayWithObject:predicate]];
	}
	else if (![predicate isKindOfClass:[NSCompoundPredicate class]])
	{
		return predicate;
	}
	
	requestedEntityName = @"Any";
	
	NSArray *subpredicates = [predicate subpredicates];
	NSMutableArray *newSubpredicates = [[NSMutableArray alloc] initWithCapacity:[subpredicates count]];
	
	for (NSComparisonPredicate *cmpP in subpredicates)
	{
		NSExpression *right = [cmpP rightExpression];
		NSExpression *left = [cmpP leftExpression];
		
		if([[left keyPath] isEqual:@"xkind"])
		{
			requestedEntityName = [right constantValue];
			continue;
		}

		if ([right expressionType] != NSConstantValueExpressionType)
		{
			[newSubpredicates addObject:cmpP];
			continue;
		}
		
		id cv = [right constantValue];
		
		if (cv && (![cv respondsToSelector:@selector(length)] || [cv length] > 0))
		{
			[newSubpredicates addObject:cmpP];
		}
	}
		
	return [[NSCompoundPredicate alloc] initWithType:[predicate compoundPredicateType] subpredicates:newSubpredicates];
}


- (NSPredicate *)predicateWithEntityNamed:(NSString **)outEntityName
{
	NSPredicate *newPredicate = [self predicate];
	
	if (outEntityName != NULL)
	{
		if([requestedEntityName isEqual:@"Class"])
		{
			requestedEntityName = @"ObjCClass";
		}
		else if([requestedEntityName isEqual:@"Function Group"])
		{
			requestedEntityName = @"FunctionContainer";
		}
		else if([requestedEntityName isEqual:@"Category"])
		{
			requestedEntityName = @"ObjCCategory";
		}
		else if([requestedEntityName isEqual:@"Protocol"])
		{
			requestedEntityName = @"ObjCProtocol";
		}
		else if([requestedEntityName isEqual:@"Bindings"])
		{
			requestedEntityName = @"ObjCBindingsListing";
		}
		
		else if([requestedEntityName isEqual:@"Method"])
		{
			requestedEntityName = @"ObjCMethod";
		}
		else if([requestedEntityName isEqual:@"Property"])
		{
			requestedEntityName = @"ObjCProperty";
		}
		else if([requestedEntityName isEqual:@"Function"])
		{
			requestedEntityName = @"CFunction";
		}
		
		else if([requestedEntityName isEqual:@"Notification"])
		{
			requestedEntityName = @"ObjCNotification";
		}
		else if([requestedEntityName isEqual:@"Global"])
		{
			requestedEntityName = @"CGlobal";
		}
		else if([requestedEntityName isEqual:@"Constant"])
		{
			requestedEntityName = @"CConstant";
		}
		
		else if([requestedEntityName isEqual:@"Enum"])
		{
			requestedEntityName = @"CEnum";
		}
		else if([requestedEntityName isEqual:@"Miscellaneous Type"])
		{
			requestedEntityName = @"CTypedef";
		}
		
		else {
			requestedEntityName = @"DocRecord";
		}

		
		*outEntityName = requestedEntityName;
	}
	return newPredicate;
}

@end
