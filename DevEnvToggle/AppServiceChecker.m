//
//  AppServiceChecker.m
//  DevEnvToggle
//
//  Created by Michael Nowak on 28.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import "AppServiceChecker.h"
#import "AppServiceHelper.h"

@implementation AppServiceChecker

+ (NSDictionary *)serviceHelperJobDictionary
{
    return (__bridge NSDictionary*)SMJobCopyDictionary(kSMDomainSystemLaunchd, (__bridge CFStringRef)serviceHelperLabel);
}

+ (NSURL *)installedHelperURL
{
    return [NSURL fileURLWithPath:[[[self serviceHelperJobDictionary] valueForKey:@"ProgramArguments"] objectAtIndex:0]];
}

+ (NSDictionary *)installedHelperInfoDictionary
{
    NSURL *installedHelperURL = [self installedHelperURL];
    return (__bridge NSDictionary*)CFBundleCopyInfoDictionaryForURL((__bridge CFURLRef)installedHelperURL);
}

+ (NSURL *)currentHelperURL
{
    NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
    return [bundleURL URLByAppendingPathComponent:[@"Contents/Library/LaunchServices/" stringByAppendingString:serviceHelperLabel]];
}

+ (NSDictionary *)currentHelperInfoDictionary
{
    NSURL *currentHelperURL = [self currentHelperURL];
    NSDictionary *currentHelperInfo = (__bridge NSDictionary*)CFBundleCopyInfoDictionaryForURL((__bridge CFURLRef)currentHelperURL);
    return currentHelperInfo;
}

+ (BOOL)checkCodeValidity
{
    SecRequirementRef requirement = NULL;
    SecStaticCodeRef staticCode = NULL;
    OSStatus err;
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *security = [(NSDictionary*) [info valueForKey:@"SMPrivilegedExecutables"] valueForKey:serviceHelperLabel];
    err = SecRequirementCreateWithString((__bridge CFStringRef)security, kSecCSDefaultFlags, &requirement);
    if (err == errSecSuccess) {
        NSURL *installedHelperURL = [self installedHelperURL];
        err = SecStaticCodeCreateWithPath((__bridge CFURLRef)installedHelperURL, kSecCSDefaultFlags, &staticCode);
        if (err == errSecSuccess) {
            err = SecStaticCodeCheckValidity(staticCode, kSecCSDefaultFlags, requirement);
            return (err == errSecSuccess) ? true : false;
        } else {
            return false;
        }
    } else {
        return false;
    }
}

+ (BOOL)checkVersionValidity
{
    NSDictionary *installedHelperInfo = [self installedHelperInfoDictionary];
    NSString *installedHelperVersion = [installedHelperInfo objectForKey:@"CFBundleVersion"];
    NSDictionary *currentHelperInfo = [self currentHelperInfoDictionary];
    NSString *currentHelperVersion = [currentHelperInfo objectForKey:@"CFBundleVersion"];
    return ([installedHelperVersion isEqual:currentHelperVersion]) ? true : false;
}

@end
