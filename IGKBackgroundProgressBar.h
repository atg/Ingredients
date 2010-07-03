//
//  IGKBackgroundProgressBar.h
//  Ingredients
//
//  Created by Alex Gordon on 17/04/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>


@interface IGKBackgroundProgressBar : NSView {
	BOOL shouldStop;
	
	//The number of pixels to translate right
	CGFloat phase;
	
	//The time interval from the reference date when the progress bar was last phased. Used to update phase
	NSTimeInterval lastUpdate;
}

- (IBAction)startAnimation:(id)sender;
- (IBAction)stopAnimation:(id)sender;

@end
