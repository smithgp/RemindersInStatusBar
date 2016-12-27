//
//  Utils.m
//  RemindersInStatusBar
//
//  Created by Greg Smith on 11/26/16.
//  Copyright © 2016 Greg Smith. All rights reserved.
//

#import "Utils.h"

@implementation Utils
+ (void)runOnMainThread:(runOnMainThread_t)r {
    if ([NSThread isMainThread]) {
        r();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), r);
    }
}

/* Show a model alert dialog.
   This needs to run on a ui main thread.
 */
+ (void)showModelAlert:(NSString*)text {
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = NSApp.accessibilityTitle;
    alert.informativeText = text;
    [alert runModal];
}


@end
