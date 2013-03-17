//
//  AppDelegate.h
//  DevEnvToggle
//
//  Created by Michael Nowak on 10.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import <Security/SecKeychain.h>

#import "AppService.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSStatusItem *statusItem;
    IBOutlet NSImage *statusImage;
    IBOutlet NSImage *statusLightImage;
    IBOutlet NSArray *services;
    IBOutlet AppService *serviceProxy;
}

- (IBAction)onToggle:(id)sender;
- (IBAction)onToggleItem:(id)sender;

- (AuthorizationRef)createAuthRef;
- (BOOL)blessHelperWithLabel:(NSString *)label withAuthRef:(AuthorizationRef)authRef error:(NSError **)error;

@property (assign) IBOutlet NSWindow *window;

@end
