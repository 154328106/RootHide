//
//  main.m
//  Dopamine
//
//  Created by Lars Fröder on 23.09.23.
//

#import <UIKit/UIKit.h>
#import "DOAppDelegate.h"

#import "DOEnvironmentManager.h"
#import <libjailbreak/info.h>
#import <libjailbreak/jbclient_xpc.h>

extern int reboot(int howto);
#ifndef RB_AUTOBOOT
#define RB_AUTOBOOT 0
#endif

int main(int argc, char * argv[]) {
    if (argc >= 3) {
        if (!strcmp(argv[1], "trollstore")) {
            if (!strcmp(argv[2], "delete-bootstrap")) {
                [[DOEnvironmentManager sharedManager] deleteBootstrap];
            }
/*
            else if (!strcmp(argv[2], "hide-jailbreak")) {
                [[DOEnvironmentManager sharedManager] setJailbreakHidden:YES];
            }
*/
            return 0;
        }
    }
    
    if (argc >= 2) {
        // Legacy, called by Dopamine 1.x before initiating a jbupdate
        // As updating from 1.x to 2.x is unsupported, just initiate a device reboot
        if (!strcmp(argv[1], "prepare_jbupdate")) {
            [[DOEnvironmentManager sharedManager] reboot];
            return 0;
        }
        // 被 exec_cmd_root 以 root 重新拉起，用于未越狱下重启设备（此时进程已是 root）
        if (!strcmp(argv[1], "do-reboot")) {
            reboot(RB_AUTOBOOT);
            return 0;
        }
    }
    
    // If systemhook isn't loaded and we are already jailbroken, we need to do the checkin ourselves
    // This can happen when the jailbreak is hidden or when tweak injection into the Dopamine app is disabled via Choicy
    jbclient_process_checkin(NULL, NULL, NULL, NULL);
    
    if ([DOEnvironmentManager sharedManager].isJailbroken) {
        setenv("PATH", "/sbin:/bin:/usr/sbin:/usr/bin:/rootfs/sbin:/rootfs/bin:/rootfs/usr/sbin:/rootfs/usr/bin", 1);
        setenv("TERM", "xterm-256color", 1);
    }
    
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([DOAppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
