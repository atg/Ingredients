//
//  IGKFilterBarTableView.h
//  Ingredients
//
//  Created by Alex Gordon on 17/04/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>
#import "IGKShyTableView.h"

@interface IGKFilterBarTableView : IGKShyTableView {

}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row;

@end
