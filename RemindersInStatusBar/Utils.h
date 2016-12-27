//
//  Utils.h
//  RemindersInStatusBar
//
//  Created by Greg Smith on 11/26/16.
//  Copyright © 2016 Greg Smith. All rights reserved.
//

#ifndef Utils_h
#define Utils_h

#import <Cocoa/Cocoa.h>

@interface Utils : NSObject

typedef void(^runOnMainThread_t)(void);
/* Run a block on the main thread.
 */
+ (void)runOnMainThread:(runOnMainThread_t)r;

/* Show a model alert dialog.
 */
+ (void)showModelAlert:(NSString*)text;
@end

#endif /* Utils_h */
