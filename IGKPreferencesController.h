//
//  IGKPreferencesController.h
//  Ingredients
//
//  Created by Alex Gordon on 07/03/2010.
//  Written in 2010 by Fileability.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/SUUpdater.h>

@interface IGKPreferencesController : NSWindowController<NSTableViewDataSource, NSTableViewDelegate>
{
	NSView *currentView;
	
	IBOutlet NSView *generalView;
	IBOutlet NSToolbarItem *generalToolbarItem;
	
	IBOutlet NSView *docsetsView;
	IBOutlet NSToolbarItem *docsetsToolbarItem;
	IBOutlet NSTableView *developerDirectoriesTableView;
	IBOutlet NSTableView *docsetsTableView;
	IBOutlet NSView *docsetsChangedStatusView;
	
	IBOutlet NSView *updatesView;
	IBOutlet NSToolbarItem *updatesToolbarItem;
	
	NSMutableArray *developerDirectories;
	NSMutableArray *docsets;
	
	BOOL startIntoDocsets;
}

@property (assign) BOOL startIntoDocsets;

- (NSManagedObjectContext *)managedObjectContext;

//Tab switching
- (IBAction)switchToGeneral:(id)sender;
- (IBAction)switchToDocsets:(id)sender;
- (IBAction)switchToUpdates:(id)sender;

//Docsets logic
- (NSString *)selectedFilterDocsetPath;
- (void)selectedFilterDocsetForPath:(NSString *)path;

- (IBAction)addDeveloperDirectory:(id)sender;
- (IBAction)removeSelectedDeveloperDirectories:(id)sender;

- (IBAction)relaunch:(id)sender;

//Updates logic
- (IBAction)checkForUpdates:(id)sender;

- (void)addDeveloperDirectoryPath:(NSString *)path;
- (int)addDocsetWithPath:(NSString *)path localizedUserInterfaceName:(NSString *)localizedUserInterfaceName developerDirectory:(NSString *)devDir;

- (void)setUpdateMatrixTag:(NSInteger)updateMatrixTag;
- (NSInteger)updateMatrixTag;

+ (IGKPreferencesController *)sharedPreferencesController;

@end
