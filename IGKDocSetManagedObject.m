//
//  IGKDocSetManagedObject.m
//  Ingredients
//
//  Created by Alex Gordon on 04/03/2010.
//  Written in 2010 by Fileability.
//

#import "IGKDocSetManagedObject.h"

NSString *IGKDocSetShortPlatformName(NSString *platformFamily)
{
	if ([platformFamily isEqual:@"macosx"])
		return @"mac";
	else if ([platformFamily isEqual:@"iphoneos"])
		return @"iphone";
	
	return platformFamily;
}
NSString *IGKDocSetShortVersionName(NSString *platformVersion)
{
	if (![platformVersion length])
		return @"unknown";
	
	return platformVersion;
}
NSString *IGKDocSetLocalizedUserInterfaceName(NSString *platformFamily, NSString *version)
{
	/* The name should be
	 Platform [Version]
	 eg
	 iPhone 3.2
	 Mac 10.6
	 */
	
	//*** Platform ***
	NSString *platform = nil;
	if ([platformFamily isEqual:@"macosx"])
		platform = @"Mac ";
	else if ([platformFamily isEqual:@"iphoneos"])
		platform = @"iPhone ";
	else if (![platformFamily length])
		platform = @"Unknown ";
	else
		platform = [platformFamily stringByAppendingString:@" "];	
	
	//*** Version ***
	if (version == nil)
		version = @"";
	
	NSString *localizedName = [platform stringByAppendingString:version];
	return localizedName;
}

@implementation IGKDocSetManagedObject

- (NSString *)sdkComponent
{
	return [NSString stringWithFormat:@"%@%@.sdk", [self valueForKey:@"platformFamily"], [self valueForKey:@"platformVersion"]];
}
- (NSString *)docsetURLHost
{
	return [NSString stringWithFormat:@"%@/%@", [self shortPlatformName], [self shortVersionName]];
}
- (NSString *)shortPlatformName
{
	return IGKDocSetShortPlatformName([self valueForKey:@"platformFamily"]);
}
- (NSString *)shortVersionName
{
	return IGKDocSetShortVersionName([self valueForKey:@"platformVersion"]);
}
- (NSString *)localizedUserInterfaceName
{
	return IGKDocSetLocalizedUserInterfaceName([self valueForKey:@"platformFamily"], [self valueForKey:@"platformVersion"]);
}

@end
