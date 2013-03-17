//
//  main.m
//  DevEnvHelper
//
//  Created by Michael Nowak on 17.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <launch.h>
#import <syslog.h>

#import "AppServiceHelper.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        syslog(LOG_NOTICE, "DevEnvHelper launched (uid: %d, euid: %d, pid: %d)", getuid(), geteuid(), getpid());
        
        launch_data_t req = launch_data_new_string(LAUNCH_KEY_CHECKIN);
        launch_data_t resp = launch_msg(req);
        launch_data_t machData = launch_data_dict_lookup(resp, LAUNCH_JOBKEY_MACHSERVICES);
        launch_data_t machPortData = launch_data_dict_lookup(machData, "com.taktsoft.DevEnvHelper.mach");
        
        mach_port_t mp = launch_data_get_machport(machPortData);
        launch_data_free(req);
        launch_data_free(resp);
        
        NSMachPort *rp = [[NSMachPort alloc] initWithMachPort:mp];
        NSConnection *c = [NSConnection connectionWithReceivePort:rp sendPort:nil];
        
        AppServiceHelper *obj = [AppServiceHelper new];
        [c setRootObject:obj];
        
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}

