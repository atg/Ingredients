//
//  IKGAnnotation.m
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-04-30.
//  Copyright 2010 SilverCocoa. All rights reserved.
//

#import "IGKAnnotation.h"
#import "NSString+Utilities.h"

@implementation IGKAnnotation

@synthesize docurl;
@synthesize submitter_name;
@synthesize uuid;
@synthesize annotation;

- (id)init
{
	if(self = [super init])
	{
		
	}
	
	return self;
}

- (id)initAndGenerateUUID
{
	if(self = [self init])
	{
		[self setUuid:[NSString stringByGeneratingUUID]];
	}
	
	return self;
}

- (id)initWithDict:(NSDictionary *)dic
{
	if (self = [self init]) {
		[self setDocurl:[dic objectForKey:@"docurl"]];
		[self setSubmitter_name:[dic objectForKey:@"submitter_name"]];
		[self setUuid:[dic objectForKey:@"uuid"]];
		[self setAnnotation:[dic objectForKey:@"annotation"]];
	}
	
	return self;
}




@end
