//
//  IKGAnnotation.h
//  Ingredients
//
//  Created by Jean-Nicolas Jolivet on 10-04-30.
//  Written in 2010 by SilverCocoa.
//

#import <Cocoa/Cocoa.h>


@interface IGKAnnotation : NSObject {
	NSString *docurl;
	NSString *submitter_name;
	NSString *uuid;
	NSString *annotation;
	NSNumber *createdDate;
}

@property (assign) NSString *docurl;
@property (assign) NSString *submitter_name;
@property (assign) NSString *uuid;
@property (assign) NSString *annotation;
@property (assign) NSNumber *createdDate;

- (id)initWithDict:(NSDictionary *)dic;
- (id)initAndGenerateUUID;

- (NSDictionary *)annotationAsDict;

@end
