//
//  IGKDocRecordManagedObject.h
//  Ingredients
//
//  Created by Alex Gordon on 25/01/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>
#import "IGKHTMLGenerator.h"
#import "IGKManagedObject.h"
#import "CHSymbolButtonImage.h"

//Priorities of different objects when sorting the list in case of a tiebreak. From lowest priority to highest
typedef enum {
	CHPriorityOther = 0, //Any object not convered by another priority class
	CHPriorityMethod = 1,
	CHPriorityFunction = 2,
	CHPriorityType = 2, //Struct, Union, Enum, Typedef, etc
	CHPriorityBindings = 3,
	CHPriorityCategory = 4,
	CHPriorityProtocol = 5,
	CHPriorityFunctionContainer = 6,
	CHPriorityClass = 7,
	
	CHPriorityMaximum, //DON'T USE THIS! DON'T PUT ANY ENUM CONSTANTS AFTER IT. This is a placeholder element so that I can work out the maximum priority by doing CHPriorityMaximum - 1.
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
