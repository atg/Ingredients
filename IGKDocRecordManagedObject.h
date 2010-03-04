//
//  IGKDocRecordManagedObject.h
//  Ingredients
//
//  Created by Alex Gordon on 25/01/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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

@interface IGKDocRecordManagedObject : NSManagedObject {

}

- (NSImage *)normalIcon;
- (NSImage *)selectedIcon;

- (CHRecordPriority)priorityval;

- (NSString *)xcontainername;
- (IGKDocRecordManagedObject *)xcontainer;

@end
