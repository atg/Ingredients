//
//  IKGAnnotationManager.h
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-04-30.
//  Copyright 2010 SilverCocoa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IGKAnnotation;

@interface IGKAnnotationManager : NSObject {
	NSMutableArray *annotations;
}

@property (assign) NSMutableArray *annotations;

+ (IGKAnnotationManager *)sharedAnnotationManager;
- (BOOL)loadAnnotations;
- (void)saveAnnotations;

- (void)addAnnotation:(IGKAnnotation *)newAnnotation;
- (NSArray *)annotationsForURL:(NSString *)URL;

@end
