//
//  DicomUnEnhancer+Versions.m
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 7/12/17.
//
//

#import "DicomUnEnhancer+Versions.h"
//#include <execinfo.h>
#include <sys/sysctl.h>
#include <OsiriX/N2Shell.h>
#include <OsiriX/N2WebServiceClient.h>
#include <OsiriX/JSON.h>
#include <OsiriX/BrowserController.h>

@implementation DicomUnEnhancer (Versions)

+ (NSString*)sysctl:(NSString*)key {
    size_t len = 0;
    sysctlbyname(key.UTF8String, NULL, &len, NULL, 0);
    
    if (len) {
        char* buffer = (char*)malloc((len+1)*sizeof(char));
        sysctlbyname(key.UTF8String, buffer, &len, NULL, 0);
        NSString* value = [NSString stringWithUTF8String:buffer];
        free(buffer);
        return value;
    }
    
    return nil;
}

+ (BOOL)sysctl:(NSString*)key into4B:(uint32_t*)v {
    size_t len = 0;
    sysctlbyname(key.UTF8String, NULL, &len, NULL, 0);
    
    if (len == 4) {
        sysctlbyname(key.UTF8String, v, &len, NULL, 0);
        return YES;
    }
    
    *v = 0;
    return NO;
}

+ (BOOL)sysctl:(NSString*)key into8B:(uint64_t*)v {
    size_t len = 0;
    sysctlbyname(key.UTF8String, NULL, &len, NULL, 0);
    
    if (len == 8) {
        sysctlbyname(key.UTF8String, v, &len, NULL, 0);
        return YES;
    }
    
    *v = 0;
    return NO;
}

+ (BOOL)version:(NSString *)newVersion isHigherThan:(NSString *)currVersion {
    NSArray<NSString *> *nva = [newVersion componentsSeparatedByString:@"."], *cva = [currVersion componentsSeparatedByString:@"."];
    for (NSInteger i = 0; i < nva.count; ++i) {
        if (cva.count <= i) // curr, say 1.2, doesn't have the extra dot, say 1.2.1
            return YES;
        if (nva[i].integerValue > cva[i].integerValue)
            return YES;
        if (nva[i].integerValue < cva[i].integerValue)
            return NO;
    }
    
    return NO;
}

- (void)checkVersion {
    [NSThread detachNewThreadWithBlock:^{
        NSString *version = [[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"] retain];
        
//        NSString *macOS = [[NSProcessInfo processInfo] operatingSystemVersionString];
//        
//        NSString *serialno = nil;
//        io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
//        if (platformExpert) {
//            CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0);
//            serialno = [(NSString*)serialNumberAsCFString autorelease];
//            IOObjectRelease(platformExpert);
//        }
//        if (!serialno) serialno = @"";
//        
//        NSString* model = [[self class] sysctl:@"hw.model"]; // MacPro5,1 / iMac7,1 / ...
//        uint64_t memsize; [[self class] sysctl:@"hw.memsize" into8B:&memsize]; CGFloat memsizegb = 1.*memsize/1024/1024/1024; // ram in GB
//        uint32_t physicalcpu; [[self class] sysctl:@"hw.physicalcpu" into4B:&physicalcpu]; // number of cores
//        uint64_t cpufrequency; [[self class] sysctl:@"hw.cpufrequency" into8B:&cpufrequency]; CGFloat cpufrequencyghz = 1.*cpufrequency/1000000000; // cpu frequency, in GHz
//        
//        uint32_t noprocs = 1;
//        @try {
//            NSString* spxml = [N2Shell execute:@"/usr/sbin/system_profiler" arguments:[NSArray arrayWithObjects: @"-xml", @"SPHardwareDataType", nil]];
//            NSData* spdata = [spxml dataUsingEncoding:NSUTF8StringEncoding];
//            NSArray* sp = [NSPropertyListSerialization propertyListWithData:spdata options:NSPropertyListImmutable format:NULL error:NULL];
//            noprocs = [[[[[sp objectAtIndex:0] objectForKey:@"_items"] objectAtIndex:0] objectForKey:@"packages"] unsignedIntValue];
//        } @catch (...) {
//            // nothing
//        }
//        
//        NSString *info = [[[NSString alloc] initWithFormat:@"%@ %dx%dx%.02fGHz %dGB", model, noprocs, (int)physicalcpu/noprocs, cpufrequencyghz, (int)memsizegb] autorelease];
        
        NSString *json = nil;
        N2WebServiceClient *cli = [[[N2WebServiceClient alloc] initWithURL:[NSURL URLWithString:@"https://www.volz.io/products/DicomUnEnhancer/version.json"]] autorelease];
        @try {
            NSData *data = [cli getWithParameters:@{ @"version": version /*, @"macOS": macOS, @"serial": serialno, @"info": info*/ }]; // postWithParameters
            json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        } @catch (NSException *e) {
            // error...
        }
        
        NSDictionary *response = [json JSONValue];
        if (![response isKindOfClass:NSDictionary.class])
            response = nil;
        
        BOOL newer = response && [[self class] version:response[@"version"] isHigherThan:version];
        
        if (newer) {
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                
                if (newer) {
                    alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"An updated version of DicomUnEnhancer is available for download (version %@).", nil), response[@"version"]];
                    alert.informativeText = NSLocalizedString(@"Please download and install the updated version.", nil);
                    
                    NSButton *ok = [alert addButtonWithTitle:NSLocalizedString(@"Update", nil)];
                    ok.tag = NSFileHandlingPanelOKButton;
                    NSButton *cancel = [alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
                    cancel.tag = NSFileHandlingPanelCancelButton;
                    cancel.keyEquivalent = @"\e";
                }
                
                while (![[[BrowserController currentBrowser] window] isVisible])
                    [NSThread sleepForTimeInterval:1];
                
                [alert beginSheetModalForWindow:[[BrowserController currentBrowser] window] completionHandler:^(NSModalResponse returnCode) {
                    if (returnCode != NSFileHandlingPanelOKButton)
                        return;
                    
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:response[@"html"] relativeToURL:cli.url]];
                }];
            }];
        }
        
    }];
}

@end
