//
//  AppService.m
//  DevEnvToggle
//
//  Created by Michael Nowak on 17.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import "AppService.h"

@implementation AppService

- (BOOL)status:(NSString *)job
{
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/bin/launchctl"];
    [task setArguments:[NSArray arrayWithObjects:@"list", job, nil]];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] == 0) {
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
