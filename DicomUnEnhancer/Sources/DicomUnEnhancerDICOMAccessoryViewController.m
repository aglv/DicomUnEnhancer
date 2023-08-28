//
//  DicomUnEnhancerDICOMAccessoryViewController.m
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 8/28/23.
//

#import "DicomUnEnhancerDICOMAccessoryViewController.h"
#import "DicomUnEnhancer+Defaults.h"

//typedef NS_ENUM(NSInteger, DicomUnEnhancerDicomMode) {
//    ExportModeLibrary = 0,
//    ExportModeFilesystem = 1,
//};

@interface DicomUnEnhancerDICOMAccessoryViewController () {
}

@property (getter=mode) DicomUnEnhancerDicomMode mode;

@property BOOL modeLibrary;
@property BOOL modeFilesystem;

@end

@implementation DicomUnEnhancerDICOMAccessoryViewController

@dynamic mode, modeLibrary, modeFilesystem;

- (void)dealloc {
    [super dealloc];
}

- (NSUserDefaults *)defaults {
    return [NSUserDefaults standardUserDefaults];
}

+ (NSSet *)keyPathsForValuesAffectingMode {
    return [NSSet setWithObject:[NSStringFromSelector(@selector(defaults)) stringByAppendingPathExtension:DicomUnEnhancerDicomModeDefaultsKey]];
}

- (DicomUnEnhancerDicomMode)mode {
    return [self.defaults integerForKey:DicomUnEnhancerDicomModeDefaultsKey];
}

- (void)setMode:(DicomUnEnhancerDicomMode)mode {
    [self.defaults setInteger:mode forKey:DicomUnEnhancerDicomModeDefaultsKey];
}

+ (NSSet *)keyPathsForValuesAffectingModeLibrary {
    return [NSSet setWithObject:NSStringFromSelector(@selector(mode))];
}

- (BOOL)modeLibrary {
    return self.mode == DicomUnEnhancerDicomModeLibrary;
}

- (void)setModeLibrary:(BOOL)flag {
    if (flag)
        self.mode = DicomUnEnhancerDicomModeLibrary;
}

+ (NSSet *)keyPathsForValuesAffectingModeFilesystem {
    return [NSSet setWithObject:NSStringFromSelector(@selector(mode))];
}

- (BOOL)modeFilesystem {
    return self.mode == DicomUnEnhancerDicomModeFilesystem;
}

- (void)setModeFilesystem:(BOOL)flag {
    if (flag)
        self.mode = DicomUnEnhancerDicomModeFilesystem;
}

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do view setup here.
//}

@end
