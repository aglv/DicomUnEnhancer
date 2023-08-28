//
//  DicomUnEnhancer+Defaults.mm
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 17.10.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomUnEnhancer+Defaults.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/NSUserDefaultsController+N2.h>
#pragma clang diagnostic pop

NSString * const DicomUnEnhancerDicomModeDefaultsKey = @"DicomUnEnhancerDICOMModeTag";
NSString * const DicomUnEnhancerNIfTIOutputNamingDefaultsKey = @"DicomUnEnhancerNIfTIOutputNaming";
NSString * const DicomUnEnhancerNIfTIReorientToNearestOrthogonalDefaultsKey = @"DicomUnEnhancerNIfTIReorientToNearestOrthogonal";
NSString * const DicomUnEnhancerNIfTIAnonymizeDefaultsKey = @"DicomUnEnhancerNIfTIAnonymize";
NSString * const DicomUnEnhancerNIfTIGzipOutputDefaultsKey = @"DicomUnEnhancerNIfTIGzipOutput";

@interface _DicomUnEnhancerDefaultsHelper : NSObject

@end

@implementation DicomUnEnhancer (Defaults)

-(void)_initDefaults {
    [[_DicomUnEnhancerDefaultsHelper alloc] init];
}

@end

@implementation _DicomUnEnhancerDefaultsHelper

-(id)init {
    if (([super init])) {
        NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
        [defaults registerDefaults:@{ DicomUnEnhancerNIfTIOutputNamingDefaultsKey: @"%p_%t_%s",
                                      DicomUnEnhancerDicomModeDefaultsKey: @(DicomUnEnhancerDicomModeLibrary),
                                      DicomUnEnhancerNIfTIAnonymizeDefaultsKey: @NO,
                                      DicomUnEnhancerNIfTIGzipOutputDefaultsKey: @NO }];
//        [defaults addObserver:self forValuesKey:DicomUnEnhancerNIfTIOutputNamingDateDefaultsKey options:NSKeyValueObservingOptionInitial context:nil];
//        [defaults addObserver:self forValuesKey:DicomUnEnhancerNIfTIOutputNamingEventsDefaultsKey options:NSKeyValueObservingOptionInitial context:nil];
//        [defaults addObserver:self forValuesKey:DicomUnEnhancerNIfTIOutputNamingIDDefaultsKey options:NSKeyValueObservingOptionInitial context:nil];
//        [defaults addObserver:self forValuesKey:DicomUnEnhancerNIfTIOutputNamingProtocolDefaultsKey options:NSKeyValueObservingOptionInitial context:nil];
    }
    
    return self;
}

//-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
//    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
//    BOOL anySpecialIsOn = [defaults boolForKey:DicomUnEnhancerNIfTIOutputNamingEventsDefaultsKey]
//                       || [defaults boolForKey:DicomUnEnhancerNIfTIOutputNamingIDDefaultsKey]
//                       || [defaults boolForKey:DicomUnEnhancerNIfTIOutputNamingProtocolDefaultsKey];
//    if (!anySpecialIsOn) [defaults setBool:YES forKey:DicomUnEnhancerNIfTIOutputNamingDateDefaultsKey];
//}

@end
