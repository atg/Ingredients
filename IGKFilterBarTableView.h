//
//  IGKFilterBarTableView.h
//  Ingredients
//
//  Created by Alex Gordon on 17/04/2010.
//  Copyright 2010 Fileability. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IGKShyTableView.h"

@interface IGKFilterBarTableView : IGKShyTableView {

}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row;

@end
