//
//  DicomUnEnhancer.h
//  DicomUnEnhancer
//
//  Copyright (c) 2011 OsiriX. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/PluginFilter.h>
#pragma clang diagnostic pop

@interface DicomUnEnhancer : PluginFilter

- (long)filterImage:(NSString *)menuName;

@end
