//
//  IGKEaseInOutAnimatedView.m
//  Ingredients
//
//  Created by Alex Gordon on 11/03/2010.
//  Written in 2010 by Fileability.
//

#import "IGKEaseInOutAnimatedView.h"


@implementation IGKEaseInOutAnimatedView

- (id)animationForKey:(NSString *)key
{
	CAAnimation *animation = [super animationForKey:key];
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	return animation;
}

@end
