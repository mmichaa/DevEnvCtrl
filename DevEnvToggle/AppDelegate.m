//
//  AppDelegate.m
//  DevEnvToggle
//
//  Created by Michael Nowak on 10.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

/*
@synthesize statusMenu;
@synthesize statusItem;
@synthesize statusImage;
@synthesize statusLightImage;
*/

/*
@synthesize services;
@synthesize serviceHelperProxy;
*/

- (void)awakeFromNib{
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *icons = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"DevEnvIcon-Black" ofType:@"icns"]] representations];
    for (NSImageRep *iconRepresentation in icons) {
        if (iconRepresentation.size.width == 16) {
            statusImage = [[NSImage alloc] init];
            [statusImage addRepresentation:iconRepresentation];
            break;
        }
    }
    NSArray *lightIcons = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"DevEnvIcon-White" ofType:@"icns"]] representations];
    for (NSImageRep *iconRepresentation in lightIcons) {
        if (iconRepresentation.size.width == 16) {
            statusLightImage = [[NSImage alloc] init];
            [statusLightImage addRepresentation:iconRepresentation];
            break;
        }
    }
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [statusItem setImage:statusImage];
    [statusItem setAlternateImage:statusLightImage];
    [statusItem setMenu:statusMenu];
    [statusItem setAction:@selector(onClick:)];
    [statusItem setToolTip:@"DevEnvToggle"];
    [statusItem setHighlightMode:YES];;
    // read service-plists and add menu-items
    NSArray *serviceFiles = [AppServiceData serviceDataFiles:[self applicationSupportDirectory]];
    if ([serviceFiles count] == 0) {
        serviceFiles = [AppServiceData serviceDataInstall:[self applicationSupportDirectory]];
    }
    services = [NSMutableArray arrayWithCapacity:[serviceFiles count]];
    int serviceIdx = 2;
    for (NSString *serviceFile in serviceFiles) {
        AppServiceData *service = [AppServiceData serviceDataWithContentsOfFile:serviceFile];
        NSMenuItem *serviceItem = [NSMenuItem new];
        [serviceItem setTitle:[service label]];
        [serviceItem setAction:@selector(onToggleItem:)];
        [serviceItem setKeyEquivalent:[[[service label] substringToIndex:1] lowercaseString]];
        [serviceItem setKeyEquivalentModifierMask:NSCommandKeyMask];
        [serviceItem setState:NSMixedState];
        if ([service plistPathExsists]) {
            [serviceItem setEnabled:YES];
        } else {
            [serviceItem setEnabled:NO];
        }
        [serviceItem setHidden:NO];
        [statusMenu insertItem:serviceItem atIndex:serviceIdx];
        [services addObject:service];
        serviceIdx++;
    }
}

- (void)menuWillOpen:(NSMenu *)menu
{
    NSLog(@"menuWillOpen: reading states and updating UI ...");
    // Set States
    for (AppServiceData *service in services) {
        NSMenuItem *serviceItem = [menu itemWithTitle:[service label]];
        [serviceItem setState:[serviceHelperProxy status:[service job]] ? NSOnState : NSOffState];
    }
}

- (IBAction)onToggle:(id)sender {
    for (AppServiceData *service in services) {
        NSString *label = [service label];
        NSMenuItem *serviceItem = [statusMenu itemWithTitle:label];
        [self onToggleItem:serviceItem];
    }
}

- (IBAction)onToggleItem:(id)sender {
    NSMenuItem *serviceItem = sender;
    for (AppServiceData *service in services) {
        if ([service label] == [serviceItem title]) {
            NSString *job = [service job];
            NSString *plistPath = [service plistPath];
            if([serviceHelperProxy status:job]) {
                NSLog(@"Stoping ToggleItem '%@' ...", job);
                [serviceHelperProxy stop:plistPath];
                if ([service diskimage]) {
                    if (![service diskimageDetach]) {
                        NSLog(@"Error detaching DiskImage!");
                        break;
                    }
                }
            } else {
                if ([service diskimage]) {
                    NSLog(@"Attaching DiskImage '%@' ...", [service diskimagePath]);
                    if (![service diskimageAttach]) {
                        NSLog(@"Error attaching DiskImage!");
                        break;
                    }
                }
                NSLog(@"Starting ToggleItem '%@' ...", job);
                [serviceHelperProxy start:plistPath];
            }
            break;
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Check Helper
    NSDictionary *plist = [AppServiceChecker serviceHelperJobDictionary];
    if (!plist) {
        [self installHelperWithLabel:serviceHelperLabel];
    } else {
        BOOL codeValidity = true; // [AppServiceChecker checkCodeValidity];
        BOOL versionValidity = true; // [AppServiceChecker checkVersionValidity];
        if (!codeValidity || !versionValidity) {
            [self installHelperWithLabel:serviceHelperLabel];
        }
    }
    // Connect to Helper
    NSConnection *c = [NSConnection connectionWithRegisteredName:serviceHelperMachLabel host:nil];
    serviceHelperProxy = (AppServiceHelper *)[c rootProxy];
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

-(BOOL)installHelperWithLabel:(NSString *)label
{
    // Get Authorization
    AuthorizationRef authRef = [self createAuthRef];
    if (authRef == NULL) {
        NSLog(@"Authorization failed");
        return false;
    }
    
    // Bless (Install) Helper
    NSError *error = nil;
    if (![self blessHelperWithLabel:label withAuthRef:authRef error:&error]) {
        NSLog(@"Failed to bless helper");
        return false;
    } else {
        return true;
    }
}

- (BOOL)blessHelperWithLabel:(NSString *)label withAuthRef:(AuthorizationRef)authRef error:(NSError **)error
{
    CFErrorRef err = NULL;
    BOOL result;
    /*
    result = SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, true, &err);
    if (result) {
        NSLog(@"Job '%@' removed!", label);
    } else {
        NSLog(@"Job '%@' not removed!", label);
    }
     */
    result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, &err);
    if (result) {
        NSLog(@"Job '%@' blessed!", label);
    } else {
        NSLog(@"Job '%@' not blessed!", label);
    }
    *error = (__bridge NSError *)err;
    
    return result;
}

- (NSString *)applicationSupportDirectory
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *supportPath = [searchPaths objectAtIndex:0];
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSString *applicationSupportPath = [supportPath stringByAppendingPathComponent:executableName];
    NSError *error;
    BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (result) {
        //NSLog(@"applicationSupportDirectory: %@", applicationSupportPath);
        return applicationSupportPath;
    } else {
        //NSLog(@"applicationSupportDirectory: %@", [error localizedDescription]);
        return nil;
    }
}

@end
