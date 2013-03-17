//
//  AppDelegate.m
//  DevEnvToggle
//
//  Created by Michael Nowak on 10.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSBundle *bundle = [NSBundle mainBundle];
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcode-draw-16x16" ofType:@"png"]];
    //statusLightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"wrench" ofType:@"gif"]];
    [statusItem setImage:statusImage];
    //[statusItem setAlternateImage:statusLightImage];
    [statusItem setMenu:statusMenu];
    //[statusItem setTitle:@"DevEnv"];
    //[statusItem setToolTip:@"Status: xxx"];
    [statusItem setHighlightMode:YES];;
    services = [NSArray arrayWithContentsOfFile:[bundle pathForResource:@"DevEnvToggle-Services" ofType:@"plist"]];
    int serviceIdx = 2;
    for (NSDictionary *service in services) {
        NSString *label = [service valueForKey:@"label"];
        NSMenuItem *serviceItem = [[NSMenuItem alloc] initWithTitle:label action:@selector(onToggleItem:) keyEquivalent:[label substringToIndex:1]];
        [serviceItem setState:NSMixedState];
        [serviceItem setEnabled:true];
        [serviceItem setHidden:false];
        [statusMenu insertItem:serviceItem atIndex:serviceIdx];
        serviceIdx++;
        //--
        NSDictionary *diskimage = [service valueForKey:@"diskimage"];
        if (diskimage) {
            NSLog(@"Disk-Image for %@", label);
            NSString *path = [diskimage valueForKey:@"path"];
            NSURL *url = [NSURL fileURLWithPath:path isDirectory:true];
            NSArray *options = [diskimage valueForKey:@"options"];
            NSString *pass = nil;
            NSMutableArray *args = [NSMutableArray arrayWithObjects:@"attach", nil];
            [args addObject:path];
            if (options && [options indexOfObjectIdenticalTo:@"-encryption"]) {
                [args addObjectsFromArray:options];
                SecKeychainRef *keychain = nil;
                SecKeychainItemRef *itemref = nil;
                SecKeychainCopyDefault(keychain);
                NSString *serviceName = [url lastPathComponent];
                UInt32 passLen = 0;
                void *passData;
                OSStatus error = SecKeychainFindGenericPassword(keychain, [serviceName length], [serviceName cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, &passLen, &passData, itemref);
                if (error == noErr) {
                    pass = [[NSString alloc] initWithBytes:passData length:passLen encoding:NSUTF8StringEncoding];
                    NSLog(@"Password: %@", pass);
                }
            }
            NSTask *task = [NSTask new];
            NSPipe *pipe =[NSPipe pipe];
            [task setLaunchPath:@"/usr/bin/hdiutil"];
            [task setArguments:args];
            [task setStandardInput:pipe];
            [task launch];
            if (pass) {
              NSFileHandle *input = [pipe fileHandleForWriting];
              [input writeData:[pass dataUsingEncoding:NSUTF8StringEncoding]];
              [input writeData:[@"\0" dataUsingEncoding:NSUTF8StringEncoding]];
            }
            [task waitUntilExit];
            if ([task terminationStatus] == 0) {
                NSLog(@"Mounted Disk-Image '%@' for Service '%@'", path, label);
            } else {
                NSLog(@"Error mounting Disk-Image '%@' for Service '%@'", path, label);
            }
        };
    }
}

- (IBAction)onToggle:(id)sender {
    NSLog(@"onToggle");
}

- (IBAction)onToggleItem:(id)sender {
    NSLog(@"onToggleItem");
    NSMenuItem *serviceItem = sender;
    for (NSDictionary *service in services) {
        if ([service valueForKey:@"label"] == [serviceItem title]) {
            NSString *path = [service valueForKey:@"path"];
            NSString *job = [service valueForKey:@"job"];
            NSString *plist = [[NSArray arrayWithObjects:path, @"/", job, @".plist", nil]componentsJoinedByString:@""];
            if([serviceProxy status:job]) {
                NSLog(@"Stoping ToggleItem ...");
                [serviceProxy stop:plist];
                [serviceItem setState:NSOffState];
            } else {
                NSLog(@"Starting ToggleItem ...");
                [serviceProxy start:plist];
                [serviceItem setState:NSOnState];
            }
            
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Get authorization
    AuthorizationRef authRef = [self createAuthRef];
    if (authRef == NULL) {
        NSLog(@"Authorization failed");
        return;
    }
    
    // Bless Helper
    NSError *error = nil;
    if (![self blessHelperWithLabel:@"com.taktsoft.DevEnvHelper" withAuthRef:authRef error:&error]) {
        NSLog(@"Failed to bless helper");
        return;
    }

    // Connect to Helper
    NSLog(@"Connecting to Helper");
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.taktsoft.DevEnvHelper.mach" host:nil];
    serviceProxy = (AppService *)[c rootProxy];

    // Set States
    for (NSDictionary *service in services) {
        NSMenuItem *serviceItem = [statusMenu itemWithTitle:[service valueForKey:@"label"]];
        [serviceItem setState:[serviceProxy status:[service valueForKey:@"job"]] ? NSOnState : NSOffState];
    }
}

- (AuthorizationRef)createAuthRef
{
    AuthorizationRef authRef = NULL;
    AuthorizationItem authItem = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights = { 1, &authItem };
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status != errAuthorizationSuccess) {
        NSLog(@"Failed to create AuthorizationRef, return code %i", status);
    }
    
    return authRef;
}

- (BOOL)blessHelperWithLabel:(NSString *)label withAuthRef:(AuthorizationRef)authRef error:(NSError **)error
{
    CFErrorRef err;
    BOOL result;
    result = SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, true, &err);
    if (result) {
        NSLog(@"Job removed!");
    } else {
        NSLog(@"Job not removed!");
    }
    result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, &err);
    if (result) {
        NSLog(@"Job blessed!");
    } else {
        NSLog(@"Job not blessed!");
    }
    *error = (__bridge NSError *)err;
    
    return result;
}

@end
