//
//  DicomUnEnhancer.h
//  DicomUnEnhancer
//
//  Copyright (c) 2011 OsiriX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriX/PluginFilter.h>

@interface DicomUnEnhancer : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end
