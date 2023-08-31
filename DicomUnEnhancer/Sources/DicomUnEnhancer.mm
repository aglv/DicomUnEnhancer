//
//  DicomUnEnhancer.m
//  DicomUnEnhancer
//
//  Copyright (c) 2011 OsiriX. All rights reserved.
//

#import "DicomUnEnhancer.h"
#import "DicomUnEnhancer+Defaults.h"
#import "DicomUnEnhancer+Versions.h"
#import "DicomUnEnhancerDCMTK.h"
#import "DicomUnEnhancerNIfTIAccessoryViewController.h"
#import "DicomUnEnhancerDICOMAccessoryViewController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/NSString+N2.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import <OsiriXAPI/ThreadModalForWindowController.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/DicomDatabase.h>
#pragma clang diagnostic pop

#import <objc/runtime.h>
#include <stdlib.h>

/*extern "C" {
    NSString *documentsDirectory();
}*/

enum {
    DicomUnEnhancerModeDICOM = 0,
    DicomUnEnhancerModeNIfTI
};

@interface DicomUnEnhancer () {
    NSURL *_dcm2niix_url;
}

- (void)_initToolbarItems;
- (void)_processMode:(NSInteger)mode forWindowController:(NSWindowController *)controller;

@end

@implementation DicomUnEnhancer

- (void)initPlugin {
    NSString *arch;
#ifdef __x86_64__
    arch = @"x86_64";
#else
    arch = @"arm64";
#endif
    
    if ((_dcm2niix_url = [[[NSBundle bundleForClass:[self class]] URLForResource:[@"dcm2niix-" stringByAppendingString:arch] withExtension:nil] retain]))
        NSLog(@"DicomUnEnhancer will use %@", _dcm2niix_url.lastPathComponent);
    else throw [NSException exceptionWithName:NSGenericException reason:@"dcm2niix not found" userInfo:nil];
    
    [self _initToolbarItems];
    [self _initDefaults];
    
    [self checkVersion];
}

- (oneway void)dealloc {
    [_dcm2niix_url release];
    
    [super dealloc];
}

- (long)filterImage:(NSString *)name {
    NSInteger mode = DicomUnEnhancerModeDICOM;
    if ([name.lowercaseString contains:@"nifti"]) mode = DicomUnEnhancerModeNIfTI;
    
    [self _processMode:mode forWindowController:viewerController];
    
    return 0;
}

#pragma mark Toolbars

DicomUnEnhancer *DicomUnEnhancerInstance = nil;

- (void)_initToolbarItems {
    DicomUnEnhancerInstance = self;
    
    Method method;
    IMP imp;
    
    // BrowserController
    
    Class BrowserControllerClass = NSClassFromString(@"BrowserController");
    
    method = class_getInstanceMethod(BrowserControllerClass, @selector(toolbarAllowedItemIdentifiers:));
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_DicomUnEnhancerBrowserToolbarAllowedItemIdentifiers:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DicomUnEnhancerBrowserToolbarAllowedItemIdentifiers:)));
    
    method = class_getInstanceMethod(BrowserControllerClass, @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:));
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_DicomUnEnhancerBrowserToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DicomUnEnhancerBrowserToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)));
    
    // ViewerController
    
    Class ViewerControllerClass = NSClassFromString(@"ViewerController");
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(toolbarAllowedItemIdentifiers:));
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_DicomUnEnhancerViewerToolbarAllowedItemIdentifiers:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DicomUnEnhancerViewerToolbarAllowedItemIdentifiers:)));
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:));
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_DicomUnEnhancerViewerToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DicomUnEnhancerViewerToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)));
}

NSString * const DicomUnEnhancerSaveAsNonEnhancedDicomToolbarItemIdentifier = @"DicomUnEnhancerSaveAsNonEnhancedDicom";
NSString * const DicomUnEnhancerSaveAsNIfTIToolbarItemIdentifier = @"DicomUnEnhancerSaveAsNIfTI";

- (NSArray *)_DicomUnEnhancerBrowserToolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [[self _DicomUnEnhancerBrowserToolbarAllowedItemIdentifiers:toolbar] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects: DicomUnEnhancerSaveAsNonEnhancedDicomToolbarItemIdentifier, DicomUnEnhancerSaveAsNIfTIToolbarItemIdentifier, NULL]];
}

- (NSArray *)_DicomUnEnhancerViewerToolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [[self _DicomUnEnhancerViewerToolbarAllowedItemIdentifiers:toolbar] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects: DicomUnEnhancerSaveAsNonEnhancedDicomToolbarItemIdentifier, DicomUnEnhancerSaveAsNIfTIToolbarItemIdentifier, NULL]];
}

- (NSToolbarItem *)_DicomUnEnhancerToolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    static NSString *DicomUnEnhancerIconFilePath = [[[NSBundle bundleForClass:[DicomUnEnhancer class]] pathForImageResource:@"DicomUnEnhancer"] retain];
    
    if ([itemIdentifier isEqualToString:DicomUnEnhancerSaveAsNonEnhancedDicomToolbarItemIdentifier]) {
        NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:DicomUnEnhancerSaveAsNonEnhancedDicomToolbarItemIdentifier] autorelease];
        item.image = [[NSImage alloc] initWithContentsOfFile:DicomUnEnhancerIconFilePath];
        item.minSize = item.image.size;
        item.label = item.paletteLabel = NSLocalizedString(@"UnEnhance", nil);
        item.target = DicomUnEnhancerInstance;
        item.action = @selector(_toolbarItemAction:);
        item.tag = DicomUnEnhancerModeDICOM;
        return item;
    }
    
    if ([itemIdentifier isEqualToString:DicomUnEnhancerSaveAsNIfTIToolbarItemIdentifier]) {
        static NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:DicomUnEnhancerSaveAsNIfTIToolbarItemIdentifier] autorelease];
        item.image = [[NSImage alloc] initWithContentsOfFile:DicomUnEnhancerIconFilePath];
        item.minSize = item.image.size;
        item.label = item.paletteLabel = NSLocalizedString(@"NIfTIfy", nil);
        item.target = DicomUnEnhancerInstance;
        item.action = @selector(_toolbarItemAction:);
        item.tag = DicomUnEnhancerModeNIfTI;
        return item;
    }
    
    return nil;
}

- (NSToolbarItem *)_DicomUnEnhancerViewerToolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = [DicomUnEnhancerInstance _DicomUnEnhancerToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    if (item) return item;
    return [self _DicomUnEnhancerViewerToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}

- (NSToolbarItem *)_DicomUnEnhancerBrowserToolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = [DicomUnEnhancerInstance _DicomUnEnhancerToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    if (item) return item;
    return [self _DicomUnEnhancerBrowserToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item {
    if ([item.toolbar.delegate isKindOfClass:[BrowserController class]])
        return [[(BrowserController *)item.toolbar.delegate databaseOutline] numberOfSelectedRows] >= 1;
    return YES;
}

- (void)_toolbarItemAction:(NSToolbarItem *)sender {
    if ([sender.toolbar.delegate isKindOfClass:[NSWindowController class]])
        [self _processMode:sender.tag forWindowController:(NSWindowController *)sender.toolbar.delegate];
    else NSLog(@"Warning: the toolbar delegate is not of type NSWindowController as expected, so the DicomUnEnhancer plugin cannot proceed.");
}

#pragma mark Processing

+ (NSArray *)arrayWithSet:(id)set {
    if ([set isKindOfClass:NSSet.class])
        return [set allObjects];
    return [set array];
}

+ (NSArray *)_uniqueObjectsInArray:(NSArray *)objects {
    NSMutableArray *r = [NSMutableArray array];
    
    for (id o in objects)
        if (![r containsObject:o])
            [r addObject:o];
    
    return r;
}

- (void)_seriesIn:(id)obj into:(NSMutableArray *)collection {
    if ([obj isKindOfClass:[DicomSeries class]])
        if (![collection containsObject:obj])
            [collection addObject:obj];

    if ([obj isKindOfClass:[NSArray class]])
        for (id i in obj)
            [self _seriesIn:i into:collection];
    
    if ([obj isKindOfClass:[DicomStudy class]])
        [self _seriesIn:[[(DicomStudy*)obj series] allObjects] into:collection];
    
    if ([obj isKindOfClass:[DicomImage class]])
        [self _seriesIn:[(DicomImage*)obj series] into:collection];
}

- (void)_processMode:(NSInteger)mode forWindowController:(id)controller {
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"CarelessDicomUnEnhancer"])
        if ([[NSAlert alertWithMessageText:@"DicomUnEnhancer" defaultButton:@"Continue" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"THE SOFTWARE IS PROVIDED AS IS. USE THE SOFTWARE AT YOUR OWN RISK. THE AUTHORS MAKE NO WARRANTIES AS TO PERFORMANCE OR FITNESS FOR A PARTICULAR PURPOSE, OR ANY OTHER WARRANTIES WHETHER EXPRESSED OR IMPLIED. NO ORAL OR WRITTEN COMMUNICATION FROM OR INFORMATION PROVIDED BY THE AUTHORS SHALL CREATE A WARRANTY. UNDER NO CIRCUMSTANCES SHALL THE AUTHORS BE LIABLE FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES RESULTING FROM THE USE, MISUSE, OR INABILITY TO USE THE SOFTWARE, EVEN IF THE AUTHOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. THESE EXCLUSIONS AND LIMITATIONS MAY NOT APPLY IN ALL JURISDICTIONS. YOU MAY HAVE ADDITIONAL RIGHTS AND SOME OF THESE LIMITATIONS MAY NOT APPLY TO YOU.\n\nTHIS SOFTWARE IS NOT INTENDED FOR PRIMARY DIAGNOSTIC, ONLY FOR SCIENTIFIC USAGE.\n\nTHE VERSION OF OSIRIX USED MAY NOT BE CERTIFIED AS A MEDICAL DEVICE FOR PRIMARY DIAGNOSIS. IF YOUR VERSION IS NOT CERTIFIED, YOU CAN ONLY USE OSIRIX AS A REVIEWING AND SCIENTIFIC SOFTWARE, NOT FOR PRIMARY DIAGNOSTIC.\n\nAll calculations, measurements and images provided by this software are intended only for scientific research. Any other use is entirely at the discretion and risk of the user. If you do use this software for scientific research please give appropriate credit in publications. This software may not be redistributed, sold or commercially used in any other way without prior approval of the author."] runModal] == NSAlertAlternateReturn)
            return;
    
    if (!controller)
        controller = [BrowserController currentBrowser];
    
    // get selected series
    
    NSMutableArray *series = [NSMutableArray array];
    if ([controller isKindOfClass:[ViewerController class]])
        [series addObject:[(ViewerController*)controller currentSeries]];
    else if ([controller isKindOfClass:[BrowserController class]]) {
        if ([[controller window] firstResponder] == [controller oMatrix]) {
            for (NSCell *cell in [[controller oMatrix] selectedCells])
                [series addObject:[[controller matrixViewArray] objectAtIndex:[cell tag]]];
        } else
            [self _seriesIn:[(BrowserController*)controller databaseSelection] into:series];
    }
    // remove OsiriX private series
    
    for (NSUInteger i = 0; i < series.count; ++i) {
        DicomSeries *s = [series objectAtIndex:i];
        if (![DicomStudy displaySeriesWithSOPClassUID:s.seriesSOPClassUID andSeriesDescription:s.name])
            [series removeObjectAtIndex:i--];
    }
    
    // is selection valid?
    
    if (series.count < 1) {
        NSBeginAlertSheet(nil, nil, nil, nil, [controller window], nil, nil, nil, nil, NSLocalizedString(@"The current selection is invalid.", nil));
        return;
    }
    
    // for every series, find out which ones are multiframes
    
    NSMutableDictionary *multiframePaths = [NSMutableDictionary dictionary];
    NSMutableDictionary *monoframePaths = [NSMutableDictionary dictionary];
    
    for (DicomSeries *s in series) {
        NSArray *paths = [[self class] _uniqueObjectsInArray:[[DicomUnEnhancer arrayWithSet:s.images] valueForKey:@"completePath"]];
        if (s.images.count > 1 && paths.count == 1) // 1 file, many images -> multiframe
            [multiframePaths setObject:[paths objectAtIndex:0] forKey:s.objectID]; // there's only 1 path in paths
        else [monoframePaths setObject:paths forKey:s.objectID];
    }
    
    // GUI: what does the user want us to do?
    
    NSOpenPanel *panel = [[[NSOpenPanel alloc] init] autorelease];
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;
    panel.canCreateDirectories = YES;
    panel.prompt = NSLocalizedString(@"OK", nil);
    
    switch (mode) {
        case DicomUnEnhancerModeNIfTI:
            panel.title = @"NIfTI";
            panel.message = [NSString stringWithFormat:NSLocalizedString(@"You are exporting %u series. Please choose a location where the generated NIfTI files will be saved.", nil), (uint32_t)series.count];
            panel.accessoryView = [[[DicomUnEnhancerNIfTIAccessoryViewController alloc] initWithNibName:@"NIfTIAccessoryView" bundle:[NSBundle bundleForClass:[self class]]] view];
            break;
        case DicomUnEnhancerModeDICOM:
            panel.title = @"DICOM";
            panel.message = [NSString stringWithFormat:NSLocalizedString(@"You are exporting %u series. Please choose a location where the generated DICOM files will be saved.", nil), (uint32_t)series.count];
            panel.accessoryView = [[[DicomUnEnhancerDICOMAccessoryViewController alloc] initWithNibName:@"DICOMAccessoryView" bundle:[NSBundle bundleForClass:[self class]]] view];
            break;
    }

    if ([panel respondsToSelector:@selector(isAccessoryViewDisclosed)])
        panel.accessoryViewDisclosed = YES;

    [panel beginSheetModalForWindow:[controller window] completionHandler:^(NSInteger result) {
        NSString *destDirPath = panel.URL.path;
        [panel orderOut:self];
        
        [panel.accessoryView autorelease];
        
        if (!result)
            return;
        
        id c = controller;
        if ([c isKindOfClass:[ViewerController class]]) {
            [[c window] close];
            c = BrowserController.currentBrowser;
            [[c window] makeKeyAndOrderFront:self];
        }
        
        NSThread *thread = [[[NSThread alloc] initWithTarget:self selector:@selector(_processInBackground:) object:[NSArray arrayWithObjects: [NSNumber numberWithInteger:mode], multiframePaths, monoframePaths, destDirPath, c, nil]] autorelease];
        thread.name = [NSString stringWithFormat:NSLocalizedString(@"UnEnhancing %u %@...", nil), (uint32_t)series.count, (series.count == 1 ? NSLocalizedString(@"series", @"singular") : NSLocalizedString(@"series", @"plural"))];
        [thread startModalForWindow:[c window]];
        [thread start];
    }];
}

- (void)_processInBackground:(NSArray *)params {
    @autoreleasepool {
        @try {
            NSThread *thread = [NSThread currentThread];

            NSInteger mode = [[params objectAtIndex:0] integerValue];
            NSMutableDictionary *multiframePaths = [params objectAtIndex:1];
            NSMutableDictionary *monoframePaths = [params objectAtIndex:2];
            NSString *destDirPath = [params objectAtIndex:3];
            BrowserController *browser = [params objectAtIndex:4];
            DicomDatabase *database = [browser database];
            
            BOOL replaceDicomFiles = (mode == DicomUnEnhancerModeDICOM) && ([NSUserDefaults.standardUserDefaults integerForKey:DicomUnEnhancerDicomModeDefaultsKey] == DicomUnEnhancerDicomModeLibrary);
            
            if (replaceDicomFiles) {
                destDirPath = [NSFileManager.defaultManager tmpFilePathInDir:[database tempDirPath]];
                [NSFileManager.defaultManager confirmDirectoryAtPath:destDirPath];
            }
            
            // convert multiframes to monoframes
            
            for (NSUInteger i = 0; i < multiframePaths.count; ++i) {
                thread.status = [NSString stringWithFormat:NSLocalizedString(@"Processing multiframe %u of %u...", nil), (uint32_t)i+1, (uint32_t)multiframePaths.count];
                NSManagedObjectID *sid = [multiframePaths.allKeys objectAtIndex:i];
                NSString *path = [multiframePaths objectForKey:sid];
                NSString *dir = destDirPath;
                if (mode == DicomUnEnhancerModeNIfTI) dir = @"/tmp";
                [monoframePaths setObject:[DicomUnEnhancerDCMTK processFileAtPath:path intoDirInPath:dir] forKey:sid];
            }
            
            thread.progress = -1;
            
            if (mode == DicomUnEnhancerModeDICOM) {
                if (replaceDicomFiles) {
                    if (multiframePaths.count) {
                        thread.status = NSLocalizedString(@"Removing multiframe data from database...", nil);
                        
                        NSMutableArray *multiframeImages = [NSMutableArray array];
                        NSMutableDictionary *seriesAlbums = [NSMutableDictionary dictionary];
                        for (NSManagedObjectID *sid in multiframePaths) {
                            DicomSeries* series = [database objectWithID:sid];
                            // images
                            [multiframeImages addObjectsFromArray:[DicomUnEnhancer arrayWithSet:[series images]]];
                            // albums
                            NSMutableArray *thisSeriesAlbums = [seriesAlbums objectForKey:sid];
                            if (!thisSeriesAlbums) [seriesAlbums setObject:(thisSeriesAlbums = [NSMutableArray array]) forKey:sid];
                            for (DicomAlbum *album in series.study.albums)
                                if (![thisSeriesAlbums containsObject:album])
                                    [thisSeriesAlbums addObject:album];
                        }
                        
                        [browser performSelectorOnMainThread:@selector(proceedDeleteObjects:) withObject:multiframeImages waitUntilDone:YES]; // TODO: YES?
                        
                        thread.status = NSLocalizedString(@"Adding monoframe data to database...", nil);
                        for (NSManagedObjectID *sid in multiframePaths) {
                            NSMutableArray *allMonoframePaths = [NSMutableArray array];
                            NSString *seriesMonoframesDirPath = [monoframePaths objectForKey:sid];
                            // move series' files to DATABASE.noindex
                            for (NSString *fromPath in [seriesMonoframesDirPath stringsByAppendingPaths:[NSFileManager.defaultManager contentsOfDirectoryAtPath:seriesMonoframesDirPath error:NULL]]) {
                                NSString *dbPath = [database uniquePathForNewDataFileWithExtension:@"dcm"];
                                [NSFileManager.defaultManager moveItemAtPath:fromPath toPath:dbPath error:NULL];
                                [allMonoframePaths addObject:dbPath];
                            }
                            // add to the db
                            [self performSelectorOnMainThread:@selector(_browserAddFilesInMainThread:) withObject:[NSArray arrayWithObjects: database, allMonoframePaths, [seriesAlbums objectForKey:sid], nil] waitUntilDone:YES]; // TODO: YES?
                        }
                    }
                } else {
                    NSInteger c = monoframePaths.count - multiframePaths.count, i = 0;
                    for (NSManagedObjectID *sid in monoframePaths) {
                        NSArray *monoframes = [monoframePaths objectForKey:sid];
                        if ([monoframes isKindOfClass:[NSArray class]]) { // a list of monoframe files that we must copy to the final location
                            thread.progress = -1;
                            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Copying monoframe %u of %u...", nil), (uint32_t)++i, (uint32_t)c];
                            NSString *seriesDir = [NSFileManager.defaultManager tmpFilePathInDir:destDirPath];
                            [NSFileManager.defaultManager confirmDirectoryAtPath:seriesDir];
                            NSUInteger i = 0;
                            for (NSString *path in monoframes) {
                                thread.progress = 1.0*i/monoframes.count;
                                [NSFileManager.defaultManager copyItemAtPath:path toPath:[seriesDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.dcm", (int)++i]] error:NULL];
                            }
                        } else ; // path to a folder containing monoframe files generated for a series, already in the final location
                    }
                }
            }
            
            thread.progress = -1;
            
            if (mode == DicomUnEnhancerModeNIfTI) {
                NSMutableArray *errors = [NSMutableArray array];
                
                for (NSUInteger i = 0; i < monoframePaths.count; ++i) {
                    thread.status = [NSString stringWithFormat:NSLocalizedString(@"Creating NIfTI %u of %u...", nil), (uint32_t)i+1, (uint32_t)monoframePaths.count];
                    thread.progress = -1;
                    
                    NSManagedObjectID *sid = [monoframePaths.allKeys objectAtIndex:i];
                    id obj = [monoframePaths objectForKey:sid];
                    
                    NSString *tmpDicomDir = nil;
                    
                    if ([obj isKindOfClass:[NSArray class]]) { // files in DB, needing to be copied into a fresh tmp dir
                        tmpDicomDir = [NSFileManager.defaultManager tmpFilePathInTmp];
                        [NSFileManager.defaultManager confirmDirectoryAtPath:tmpDicomDir];
                        NSLog(@"Copying %d files to %@", (int)[obj count], tmpDicomDir);
                        for (NSString* path in obj)
                            [NSFileManager.defaultManager copyItemAtPath:path toPath:[tmpDicomDir stringByAppendingPathComponent:[path lastPathComponent]] error:NULL];
                    } else { // path of a dir that's already in tmp
                        tmpDicomDir = obj;
                    }
                    
                    NSLog(@"Processing %@", tmpDicomDir);
                    
                    NSArray *args = @[ @"-f", [NSUserDefaults.standardUserDefaults stringForKey:DicomUnEnhancerNIfTIOutputNamingDefaultsKey],
                                       @"-o", destDirPath,
//                                       @"-t", ([NSUserDefaults.standardUserDefaults boolForKey:DicomUnEnhancerNIfTIAnonymizeDefaultsKey]? @"n" : @"y"),
                                       @"-z", ([NSUserDefaults.standardUserDefaults boolForKey:DicomUnEnhancerNIfTIGzipOutputDefaultsKey]? @"y" : @"n"),
                                       tmpDicomDir ];
                    
                    NSString *error = nil;
                    // dcm2niix sometimes fails, try up to 10 times
                    for (size_t i = 0; i < 10; ++i) {
                        NSTask *task = [[[NSTask alloc] init] autorelease];
                        task.executableURL = _dcm2niix_url;
                        task.arguments = args;
                        task.standardError = [NSPipe pipe];
                        [task launch];
                        
                        while ([task isRunning])
                            [NSThread sleepForTimeInterval:0.01];
                        
                        if ([task terminationStatus] == 0) {
                            error = nil;
                            break; // otherwise, try again
                        } else
                            error = [[NSString alloc] initWithData:[[task.standardError fileHandleForReading] availableData] encoding:NSUTF8StringEncoding];
                    }
                    
                    [NSFileManager.defaultManager removeItemAtPath:tmpDicomDir error:NULL];
                    
                    if (error)
                        [errors addObject:error];
                }
                
                if (errors.count)
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                        alert.messageText = @"DicomUnEnhance dcm2niiX error";
                        alert.informativeText = errors.firstObject;
                        alert.alertStyle = NSAlertStyleCritical;
                        [alert addButtonWithTitle:@"OK"];
                        [alert beginSheetModalForWindow:[[BrowserController currentBrowser] window] completionHandler:nil];
                    }];
            }

            thread.status = @"Done.";
            thread.progress = -1;
            
        } @catch (NSException* e) {
            NSLog(@"DicomUnEnhancer exception: %@", e.reason);
        }
    }
}

- (void)_browserAddFilesInMainThread:(NSArray *)args {
    DicomDatabase *database = [args objectAtIndex:0];
    NSArray *paths = [args objectAtIndex:1];
    NSArray *albums = [args objectAtIndex:2];
    
    NSArray *objs = [database objectsWithIDs:[database addFilesAtPaths:paths postNotifications:YES dicomOnly:YES rereadExistingItems:YES generatedByOsiriX:YES]];
    
    DicomStudy *study = [[(DicomImage*)objs[0] series] study];
    
    for (DicomAlbum *album in albums)
        if (![album.studies containsObject:study])
            [album addStudiesObject:study];
}

@end

