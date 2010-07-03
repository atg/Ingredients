//
//  AnthillBugReporter.h
//  AnthillReporter
//
//  Created by Alex Gordon on 14/02/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import <Cocoa/Cocoa.h>


@interface AnthillBugReporter : NSObject
{
	IBOutlet NSWindow *window;
	IBOutlet NSView *mainView;
	
	//Header
	IBOutlet NSTextField *headerSubText;
	
	NSView *currentView;
	
	//Compose screen
	IBOutlet NSView *composeView;
	IBOutlet NSPopUpButton *bugType;
	IBOutlet NSTextField *bugSubject;
	IBOutlet NSTextView *bugText;
	IBOutlet NSTextField *replyToLabel;
	IBOutlet NSPopUpButton *replyToEmail;
	IBOutlet NSButton *ok;
	IBOutlet NSButton *cancel;
	
	//Progress screen
	IBOutlet NSView *progressView;
	IBOutlet NSProgressIndicator *spinner;
	
	//Error/Success screen
	IBOutlet NSView *errorView;
	IBOutlet NSTextField *errorText;
	IBOutlet NSButton *goBack;

	//Custom login
	IBOutlet NSWindow *customLoginWindow;
	IBOutlet NSTextField *customLoginEmail;
	IBOutlet NSSecureTextField *customLoginPassword;
	IBOutlet NSButton *customLoginCancel;
	IBOutlet NSButton *customLoginOK;
}

- (IBAction)show:(id)sender;
- (IBAction)hide:(id)sender;
- (IBAction)toggleShown:(id)sender;

- (BOOL)isShown;
- (void)setShown:(BOOL)isShown;

//*** Private ***
- (NSArray *)emailAddressesOfUser;
- (void)switchToView:(NSView *)v fromDirection:(int)direction;

- (IBAction)replyToEmail:(id)sender;

- (IBAction)send:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)goBack:(id)sender;

- (IBAction)customLoginOK:(id)sender;
- (IBAction)customLoginCancel:(id)sender;

@end



@interface AnthillBugReporterWindowBackgroundView : NSView {
	
}

@end



@interface AnthillHTTPRequest : NSObject {
	
}

+ (NSString *)postURLString:(NSString *)urlString getItems:(NSDictionary *)getItems postItems:(NSDictionary *)postItems;
+ (NSString *)urlEncodeValue:(NSString *)str;

@end
