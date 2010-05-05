//
//  IKGAnnotationManager.h
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-04-30.
//  Copyright 2010 SilverCocoa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IGKAnnotationManager : NSObject {
	NSMutableArray *annotations;
}

@property (assign) NSMutableArray *annotations;

+ (IGKAnnotationManager *)sharedAnnotationManager;

@end
