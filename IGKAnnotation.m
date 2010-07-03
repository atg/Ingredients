//
//  IKGAnnotation.m
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-04-30.
//  Written in 2010 by SilverCocoa.
//

#import "IGKAnnotation.h"
#import "NSString+Utilities.h"

@implementation IGKAnnotation

@synthesize docurl;
@synthesize submitter_name;
@synthesize uuid;
@synthesize annotation;
@synthesize createdDate;

+ (IGKAnnotation *)createAnnotation
{
	return [[self alloc] initAndGenerateUUID];
}

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
		NSUInteger today = (NSTimeInterval)[[NSDate date] timeIntervalSince1970];
		[self setCreatedDate:[NSNumber numberWithUnsignedInt:today]];
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
		[self setCreatedDate:[dic objectForKey:@"createdDate"]];
	}
	
	return self;
}

- (NSDictionary *)annotationAsDict
{
	NSMutableDictionary *returnDic = [[NSMutableDictionary alloc] init];
	[returnDic setObject:[self docurl] forKey:@"docurl"];
	[returnDic setObject:[self submitter_name] forKey:@"submitter_name"];
	[returnDic setObject:[self uuid] forKey:@"uuid"];
	[returnDic setObject:[self annotation] forKey:@"annotation"];
	[returnDic setObject:[self createdDate] forKey:@"createdDate"];
	
	return returnDic;
	
}


@end
