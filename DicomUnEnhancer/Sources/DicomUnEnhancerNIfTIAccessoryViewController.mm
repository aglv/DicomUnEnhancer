//
//  DicomUnEnhancerNIfTIAccessoryViewController.m
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 17.10.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomUnEnhancerNIfTIAccessoryViewController.h"

@interface DicomUnEnhancerNIfTIAccessoryViewController () {
    NSButton *_outputNamingDateCheckbox;
    NSButton *_outputNamingEventsCheckbox;
    NSButton *_outputNamingIDCheckbox;
    NSButton *_outputNamingProtocolCheckbox;
}

- (IBAction)outputNamingChanged:(id)sender;

@end

@implementation DicomUnEnhancerNIfTIAccessoryViewController

@synthesize outputNamingDateCheckbox = _outputNamingDateCheckbox;
@synthesize outputNamingEventsCheckbox = _outputNamingEventsCheckbox;
@synthesize outputNamingIDCheckbox = _outputNamingIDCheckbox;
@synthesize outputNamingProtocolCheckbox = _outputNamingProtocolCheckbox;

- (IBAction)outputNamingChanged:(id)sender {
    [self.outputNamingDateCheckbox setEnabled:(self.outputNamingEventsCheckbox.state || self.outputNamingIDCheckbox.state || self.outputNamingProtocolCheckbox.state)];
}

@end
