//
//  AppServiceHelper.m
//  DevEnvCtrl
//
//  Created by Michael Nowak on 17.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import "AppServiceHelper.h"

@implementation AppServiceHelper

@synthesize domain;

+ (id)serviceHelperWithSystemDomain
{
    return [[self alloc] initWithSystemDomain];
}

- (id)initWithSystemDomain
{
    if (self = [super init]) {
        domain = kSMDomainSystemLaunchd;
    }
    return self;
}

+ (id)serviceHelperWithUserDomain
{
    return [[self alloc] initWithUserDomain];
}

- (id)initWithUserDomain
{
    if (self = [super init]) {
        domain = kSMDomainUserLaunchd;
    }
    return self;
}

- (BOOL)status:(NSString *)job
{
    NSDictionary *plist = (__bridge NSDictionary*)SMJobCopyDictionary([self domain], (__bridge CFStringRef)job);
    if (plist) {
        return true;
    } else {
        return false;
    }
}

- (BOOL)start:(NSString *)job
{
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/bin/launchctl"];
    [task setArguments:[NSArray arrayWithObjects:@"load", @"-w", job, nil]];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] == 0) {
        return true;
    } else {
        return false;
    }
}

- (BOOL)stop:(NSString *)job
{
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/bin/launchctl"];
    [task setArguments:[NSArray arrayWithObjects:@"unload", @"-w", job, nil]];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] == 0) {
        return true;
    } else {
        return false;
    }
}

@end
