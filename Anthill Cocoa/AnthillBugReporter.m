//
//  AnthillBugReporter.m
//  AnthillReporter
//
//  Created by Alex Gordon on 14/02/2009.
//  Copyright 2009 Fileability. Written in 2010 by Fileability..
//

#import "AnthillBugReporter.h"

NSString *UKCrashReporterFindTenFiveCrashReportPath(NSString* appName, NSString* crashLogsFolder)
{
	NSDirectoryEnumerator *enny = [[NSFileManager defaultManager] enumeratorAtPath: crashLogsFolder];
	NSString *currName = nil;
	NSString *crashLogPrefix = [NSString stringWithFormat: @"%@_",appName];
	NSString *crashLogSuffix = @".crash";
	NSString *foundName = nil;
	NSDate *foundDate = nil;
	
	// Find the newest of our crash log files:
	while (currName = [enny nextObject])
	{
		if ([currName hasPrefix: crashLogPrefix] && [currName hasSuffix: crashLogSuffix])
		{
			NSDate*	currDate = [[enny fileAttributes] fileModificationDate];
			if( foundName )
			{
				if( [currDate isGreaterThan: foundDate] )
				{
					foundName = currName;
					foundDate = currDate;
				}
			}
			else
			{
				foundName = currName;
				foundDate = currDate;
			}
		}
	}
	
	if (!foundName)
		return nil;
	else
		return [crashLogsFolder stringByAppendingPathComponent: foundName];
}

@implementation AnthillBugReporter

//static AnthillBugReporter *sharedBugReporter = nil;


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShutdownBad"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init
{
	if (self = [super init])
	{
		//Can an object be in two .nibs at once? Apparently it can (just don't use -awakeFromNib).
		[NSBundle loadNibNamed:@"AnthillReporter" owner:self];		
		
		[self switchToView:composeView fromDirection:0];
		
		[window center];
		
		[bugText setFont:[NSFont systemFontOfSize:13]];
		[headerSubText setStringValue:[NSString stringWithFormat:[headerSubText stringValue], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]];
		
		NSArray *addresses = [self emailAddressesOfUser];
		if ([addresses count])
		{
			[[replyToEmail menu] addItem:[NSMenuItem separatorItem]];
			[replyToEmail addItemsWithTitles:addresses];
			[replyToEmail selectItemAtIndex:2];
			
			//Make the popup menu as wide as needed, while keeping outside 20px of the buttons
			float spaceAvailiable = NSMinX([cancel frame]) - NSMaxX([replyToLabel frame]) - 8.0;
			
			[replyToEmail sizeToFit];
			if (NSMaxX([replyToEmail frame]) + 20.0 > spaceAvailiable)
			{
				NSRect newFrame = [replyToEmail frame];
				newFrame.size.width = spaceAvailiable - 20.0;
				[replyToEmail setFrame:newFrame];
			}
		}
	
	//*** Reply to Email
		[[replyToEmail menu] addItem:[NSMenuItem separatorItem]];
		NSMenuItem *customLogin = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Other Email…",@"") action:nil keyEquivalent:@""];
		[customLogin setTag:-2];
		[[replyToEmail menu] addItem:customLogin];

	
	//*** Crash detection ***	
		BOOL old = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShutdownBad"];	
		
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShutdownBad"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		if (old)
		{
			//Last time we ran the program, it shut down badly
			[self setShown:YES];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];

	}
	return self;
}

- (IBAction)show:(id)sender
{
	[self setShown:YES];
}
- (IBAction)hide:(id)sender
{
	[self setShown:NO];
}
- (IBAction)toggleShown:(id)sender
{
	[self setShown:![self isShown]];
}

- (BOOL)isShown
{
	return [window isVisible];
}
- (void)setShown:(BOOL)isShown
{
	if (isShown)
		[window makeKeyAndOrderFront:nil];
	else
		[window orderOut:nil];
}

- (IBAction)replyToEmail:(id)sender
{
	if ([[sender selectedItem] tag] == -2) //Custom login
	{
		[NSApp beginSheet:customLoginWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
}
- (IBAction)customLoginOK:(id)sender
{
	[NSApp endSheet:customLoginWindow];
	[customLoginWindow orderOut:sender];
}
- (IBAction)customLoginCancel:(id)sender
{
	[NSApp endSheet:customLoginWindow];
	[customLoginWindow orderOut:sender];
}

- (NSMutableDictionary *)buildDictionaryFromFields
{
	NSMutableDictionary *fields = [NSMutableDictionary dictionaryWithCapacity:11];
	[fields setValue:[bugSubject stringValue] forKey:@"name"];
	[fields setValue:[bugType titleOfSelectedItem] forKey:@"type"];
	[fields setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] forKey:@"appname"];
	
	NSString *password = nil;
	NSString *emailAddr = nil;
	
	if ([[replyToEmail selectedItem] tag] == 0)
	{
		emailAddr = [replyToEmail titleOfSelectedItem];
	}
	else if ([[replyToEmail selectedItem] tag] == -2)
	{
		if ([[customLoginEmail stringValue] length])
		{
			emailAddr = [customLoginEmail stringValue];
			
			if ([[customLoginPassword stringValue] length])
			{
				password = [customLoginPassword stringValue];
			}
		}
	}
	
	if (emailAddr)
	{
		[fields setValue:emailAddr forKey:@"email"];
		if (password)
		{
			[fields setValue:password forKey:@"password"];
		}
	}
	//[fields setValue: forKey:@"milestone_id"];
	
	NSString *langCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
	if ([langCode length]) 
		[fields setValue:langCode forKey:@"country"];
	
	[fields setValue:[bugText string] forKey:@"body"];
	
	return fields;
}

- (NSArray *)emailAddressesOfUser
{
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	if (![searchPaths count])
		return [NSArray array];
	
	NSString *libraryPath = [searchPaths objectAtIndex:0];
	NSString *mailPrefsPath = [[libraryPath stringByAppendingPathComponent:@"Preferences"] stringByAppendingPathComponent:@"com.apple.mail.plist"];
	
	NSDictionary *mailPreferences = [NSDictionary dictionaryWithContentsOfFile:mailPrefsPath];
	
	if (![mailPreferences count])
		return [NSArray array];
	
	NSArray *mailAccounts = [mailPreferences objectForKey:@"MailAccounts"];
	if (![mailAccounts count])
		return [NSArray array];
	
	NSMutableSet *addresses = [NSMutableSet set];
	
	//Get addresses
	for (NSDictionary *maildict in mailAccounts)
	{
		NSArray *emailAddresses = [maildict objectForKey:@"EmailAddresses"];
		for (NSString *address in emailAddresses)
		{
			if (![addresses containsObject:address])
				[addresses addObject:address];
		}
	}
	
	return [addresses allObjects];
}

- (IBAction)send:(id)sender
{
	[ok setEnabled:NO];
	[cancel setEnabled:NO];
	
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSDictionary *anthillDict = [infoDict objectForKey:@"AnthillBugReporter"];
	NSString *installationURL = [anthillDict objectForKey:@"AnthillInstallationURL"];
	NSString *projectName = [anthillDict objectForKey:@"AnthillProjectName"];

	if (!installationURL || !projectName)
	{
		[errorText setStringValue:NSLocalizedString(@"URL or project name is not configured.", @"")];
		[self switchToView:errorView fromDirection:-1];
		return;
	}
	
	if (![[bugSubject stringValue] length])
	{
		[errorText setStringValue:NSLocalizedString(@"Please enter a brief subject for the report.", @"")];
		[self switchToView:errorView fromDirection:-1];
		return;
	}
	
	[spinner startAnimation:nil];
	
	[self switchToView:progressView fromDirection:-1];
	
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"];
	NSString *userLibraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *crashLogsFolder = [[userLibraryFolder stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:@"CrashReporter"];
	NSString *crashLogPath = nil;
	NSString *crashLog = nil;
	crashLogPath = UKCrashReporterFindTenFiveCrashReportPath(appName, crashLogsFolder);
	
	NSStringEncoding enc = NSUTF8StringEncoding;
	NSError *err = nil;
	if (crashLogPath)
		crashLog = [NSString stringWithContentsOfFile:crashLogPath usedEncoding:&enc error:&err];
		
	NSString *urlString = installationURL;
	if ([urlString length] && ![[urlString substringWithRange:NSMakeRange([urlString length]-1, 1)] isEqual:@"/"])
		urlString = [urlString stringByAppendingString:@"/"];
	
	urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"%@/api/tickets/create", projectName]];
	
	NSMutableDictionary *postDictionary = [self buildDictionaryFromFields];
	if (crashLog)
		[postDictionary setValue:crashLog forKey:@"crashreport"];

	NSString *response = [AnthillHTTPRequest postURLString:urlString getItems:[NSDictionary dictionary] postItems:postDictionary];
	if (![response length])
	{
		[errorText setStringValue:NSLocalizedString(@"Could not communicate with the server. Please try again later.", @"")];
	}
	else
	{
		NSArray *items = [response componentsSeparatedByString:@";"];
		if ([items count] == 2)
		{
			[errorText setStringValue:[items objectAtIndex:1]]; //The string should have already been localized
		}
		else
		{
			[errorText setStringValue:NSLocalizedString(@"The server responded with an unknown error. Please try again later.", @"")];
		}
	}
		
	[self switchToView:errorView fromDirection:-1];
}
- (IBAction)cancel:(id)sender
{
	[self setShown:NO];
}

- (IBAction)goBack:(id)sender
{
	[self switchToView:composeView fromDirection:1];
	
	[ok setEnabled:YES];
	[cancel setEnabled:YES];
}

- (void)switchToView:(NSView *)v fromDirection:(int)direction
{
	//-1 = right->left
	//0 = no animation
	//1 = left->right
	
	NSRect rightFrame = [mainView frame];
	rightFrame.origin = NSMakePoint(rightFrame.size.width, 0);
	
	NSRect zeroFrame = [mainView frame];
	zeroFrame.origin = NSZeroPoint;
	
	NSRect leftFrame = [mainView frame];
	leftFrame.origin = NSMakePoint(-leftFrame.size.width, 0);
	
	if (currentView)
	{
		if (direction == 0)
		{
			[currentView removeFromSuperview];
		}
		else
		{
			if (direction == -1)
				[[currentView animator] setFrame:leftFrame];
			else
				[[currentView animator] setFrame:rightFrame];
			[currentView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
		}
	}
	
	currentView = v;
	
	if (direction == -1)
		[v setFrame:rightFrame];
	else if (direction == 0)
		[v setFrame:zeroFrame];
	else
		[v setFrame:leftFrame];
	
	[mainView addSubview:v];
	
	if (direction != 0)
	{
		[[v animator] setFrame:zeroFrame];
	}
	else
		[v setFrame:zeroFrame];
}

@end



@implementation AnthillBugReporterWindowBackgroundView

- (void)drawRect:(NSRect)rect
{
	rect = [self bounds];
	
	
	//Bottom bar
	NSRect fill = NSMakeRect(0, 0, rect.size.width, 38);
	[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.04] set];
	NSRectFillUsingOperation(fill, NSCompositeSourceOver);
	
	//Bottom highlight
	fill = NSMakeRect(0, 38, rect.size.width, 1);
	[[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.37] set];
	NSRectFillUsingOperation(fill, NSCompositeSourceOver);
	
	//Bottom shadow
	fill = NSMakeRect(0, 39, rect.size.width, 1);
	[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.12] set];
	NSRectFillUsingOperation(fill, NSCompositeSourceOver);
	
	
	//Top bar
	fill = NSMakeRect(0, rect.size.height - 54, rect.size.width, 54);
	[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.04] set];
	NSRectFillUsingOperation(fill, NSCompositeSourceOver);
	
	//Top shadow
	fill = NSMakeRect(0, rect.size.height - 55, rect.size.width, 1);
	[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.12] set];
	NSRectFillUsingOperation(fill, NSCompositeSourceOver);
	
	//Top highlight
	fill = NSMakeRect(0, rect.size.height - 56, rect.size.width, 1);
	[[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.37] set];
	NSRectFillUsingOperation(fill, NSCompositeSourceOver);
	
}

@end




@implementation AnthillHTTPRequest


+ (NSString *)postURLString:(NSString *)urlString getItems:(NSDictionary *)getItems postItems:(NSDictionary *)postItems
{	
	NSMutableString *url = [urlString mutableCopy];
	
	//GET
	if (getItems && [getItems count] > 0)
	{
		[url appendFormat:@"?"];
		
		int i = 0;
		int getItemsCount = [getItems count];
		for (id key in getItems)
		{
			[url appendFormat:@"%@=%@", [self urlEncodeValue:key], [self urlEncodeValue:[getItems valueForKey:key]] ];
			
			if (i < getItemsCount - 1)
				[url appendString:@"&"];
			i++;
		}
	}
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:url]];
	[url release];
	url = nil;
	
	//POST
	if (postItems && [postItems count] > 0)
	{
		NSMutableString *postString = [NSMutableString string];
		
		int i = 0;
		int postItemsCount = [postItems count];
		for (id key in postItems)
		{
			[postString appendFormat:@"%@=%@", [self urlEncodeValue:key], [self urlEncodeValue:[postItems valueForKey:key]] ];
			
			if (i < postItemsCount - 1)
				[postString appendString:@"&"];
			i++;
		}
		
		
		NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
		NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		//[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
	}
	
	return [[[NSString alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil] encoding:NSUTF8StringEncoding] autorelease];
}

+ (NSString *)urlEncodeValue:(NSString *)str
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
	return [result autorelease];
}

@end
