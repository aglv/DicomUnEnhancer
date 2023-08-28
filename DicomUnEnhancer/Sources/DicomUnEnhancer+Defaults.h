//
//  DicomUnEnhancer+Defaults.h
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 17.10.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomUnEnhancer.h"

extern NSString * const DicomUnEnhancerDicomModeDefaultsKey;
extern NSString * const DicomUnEnhancerNIfTIOutputNamingDefaultsKey;
extern NSString * const DicomUnEnhancerNIfTIReorientToNearestOrthogonalDefaultsKey;
extern NSString * const DicomUnEnhancerNIfTIAnonymizeDefaultsKey;
extern NSString * const DicomUnEnhancerNIfTIGzipOutputDefaultsKey;

typedef NS_ENUM(NSInteger, DicomUnEnhancerDicomMode) {
    DicomUnEnhancerDicomModeLibrary = 0,
    DicomUnEnhancerDicomModeFilesystem = 1,
};

//enum {
//    DicomUnEnhancerDICOMReplaceInDatabaseModeTag = 0,
//    DicomUnEnhancerDicomModeTag = 1
//};

@interface DicomUnEnhancer (Defaults)

-(void)_initDefaults;

@end
