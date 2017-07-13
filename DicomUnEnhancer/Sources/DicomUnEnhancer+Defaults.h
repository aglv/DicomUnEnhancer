//
//  DicomUnEnhancer+Defaults.h
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 17.10.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomUnEnhancer.h"

extern NSString* const DicomUnEnhancerDICOMModeTagDefaultsKey;
extern NSString* const DicomUnEnhancerNIfTIOutputNamingDefaultsKey;
extern NSString* const DicomUnEnhancerNIfTIReorientToNearestOrthogonalDefaultsKey;
extern NSString* const DicomUnEnhancerNIfTIAnonymizeDefaultsKey;
extern NSString* const DicomUnEnhancerNIfTIGzipOutputDefaultsKey;

enum {
    DicomUnEnhancerDICOMReplaceInDatabaseModeTag = 0,
    DicomUnEnhancerDICOMExportModeTag = 1
};

@interface DicomUnEnhancer (Defaults)

-(void)_initDefaults;

@end
