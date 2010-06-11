//
//  IGKDocRecordManagedObject.h
//  Ingredients
//
//  Created by Alex Gordon on 25/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IGKHTMLGenerator.h"
#import "IGKManagedObject.h"
#import "CHSymbolButtonImage.h"

//Priorities of different objects when sorting the list in case of a tiebreak. From lowest priority to highest
typedef enum {
	CHPriorityOther = 0, //Any object not convered by another priority class
	CHPriorityFunction = 1,
	CHPriorityMethod,
	CHPriorityType, //Struct, Union, Enum, Typedef, etc
	CHPriorityCategory,
	CHPriorityProtocol,
	CHPriorityClass,
} CHRecordPriority;

@interface IGKDocRecordManagedObject : IGKManagedObject {

}

+ (IGKDocRecordManagedObject *)resolveURL:(NSURL *)url inContext:(NSManagedObjectContext *)ctx tableOfContentsMask:(IGKHTMLDisplayTypeMask *)tocMaskPointer;
- (NSURL *)docURL:(IGKHTMLDisplayTypeMask)tocMask;

+ (NSString *)entityNameFromURLComponentExtension:(NSString *)ext;
- (NSString *)URLComponentExtension;

- (NSString *)URLComponent;
- (NSURL *)docURL:(IGKHTMLDisplayTypeMask)tocMask;

- (NSImage *)normalIcon;
- (NSImage *)selectedIcon;

- (CHRecordPriority)priorityval;

- (NSString *)xcontainername;
- (IGKDocRecordManagedObject *)xcontainer;

- (CHSymbolButtonImageMask)iconMask;
+ (CHSymbolButtonImageMask)iconMaskForEntity:(NSString *)entityName isInstanceMethod:(BOOL)instanceMethod;

@end
