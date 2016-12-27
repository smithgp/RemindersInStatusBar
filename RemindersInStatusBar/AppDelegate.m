//
//  AppDelegate.m
//  RemindersInStatusBar
//
//  Created by Greg Smith on 11/17/16.
//  Copyright © 2016 Greg Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "Utils.h"
#import <EventKit/EventKit.h>

@interface AppDelegate()

@property (nonatomic, strong) NSStatusItem* statusItem;
@property (nonatomic, strong) EKEventStore* eventStore;
@property (class, atomic, strong, readonly) NSDateFormatter* dueDateFormatter;
@property (class, atomic, strong, readonly) NSCalendar* calendar;

@end

@implementation AppDelegate

static NSDateFormatter* _dueDateFormatter = nil;
+ (NSDateFormatter*)dueDateFormatter {
    if (_dueDateFormatter == nil) {
        _dueDateFormatter = [[NSDateFormatter alloc] init];
        [_dueDateFormatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    }
    return _dueDateFormatter;
}

static NSCalendar* _calendar = nil;
+ (NSCalendar*)calendar {
    if (_calendar == nil) {
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    }
    return _calendar;
}

+ (NSString*)formatDueDate:(NSDateComponents*)date {
    return [AppDelegate.dueDateFormatter stringFromDate:[AppDelegate.calendar dateFromComponents:date]];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    // TODO: get a real, transparent icon
    // get the Reminders app icon
    NSImage* image = [[NSWorkspace sharedWorkspace] iconForFile:@"/Applications/Reminders.app"];
    // create up a status bar with that icon
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.image = image;
    //[self.statusItem.image setTemplate:YES];
    
    // initialize a base menu
    NSMenu* menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Initializing..." action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [self insertQuitMenuItem:menu];
    
    self.statusItem.menu = menu;

    // initialize access to the reminders
    self.eventStore = [[EKEventStore alloc] init];
    [self.eventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
        // no error
        if (error == nil) {
            // if we're not authorized, that means we will never see any reminders from the eventStore, so
            // warn about it
            if ([EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder] != EKAuthorizationStatusAuthorized) {
                [Utils runOnMainThread:^{
                    [menu removeItemAtIndex:0]; // remove Initializing...
                    // add a leading menu item that opens the reminders privacy system prefs page
                    [menu insertItem:[[NSMenuItem alloc] initWithTitle:@"Permissioned denied..." action:@selector(openRemindersPrivacyPrefs:) keyEquivalent:@""]
                             atIndex:0];
                }];
            }
            // otherwise create the reminders menu
            else {
                [Utils runOnMainThread:^{
                    [menu removeItemAtIndex:0]; // remove Initializing...
                    [self initializeMenu:menu];
                }];
            }
        }
        // error occurred, so add a menu item that shows it
        else {
            [Utils runOnMainThread:^{
                [menu removeItemAtIndex:0]; // remove Initializing...
                [menu insertItem:[[NSMenuItem alloc] initWithTitle:[@"Error: " stringByAppendingString:error.domain] action:nil keyEquivalent:@""]
                         atIndex:0];
            }];
        }
    }];
}

- (void)initializeMenu:(NSMenu*)menu {
    // add in all uncompleted tasks that have a dueDate (need to pass in non-nill startDate or you get everything)
    [self insertRemindersMenuItems:menu startingAt:0
          predicate:[self.eventStore predicateForIncompleteRemindersWithDueDateStarting:[[NSDate alloc] initWithTimeIntervalSince1970:0.0] ending:nil calendars:nil]
          sortBy:^NSComparisonResult(EKReminder* e1, EKReminder* e2) {
              // sort the reminders by their due date, which can technically be nil (but shouldn't be here)
              NSDateComponents* d1 = e1.dueDateComponents;
              NSDateComponents* d2 = e2.dueDateComponents;
              if (d1 != nil && d2 != nil) {
                  NSCalendar* c = [AppDelegate calendar];
                  return [[c dateFromComponents:d1] compare:[c dateFromComponents:d2]];
              }
              else if (d1 == d2) {
                  return NSOrderedSame;
              }
              else if (d1 != nil) {
                  return NSOrderedAscending;
              }
              return NSOrderedDescending;
          }
    ];
}

- (void)insertRemindersMenuItems:(NSMenu*)menu startingAt:(int)start predicate:(NSPredicate*)predicate
                          sortBy:(NSComparator)comparator {
    [self.eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray<EKReminder*> *reminders) {
        if (comparator != nil) {
            reminders = [reminders sortedArrayUsingComparator:comparator];
        }
        //printf("# of reminders = %d", (int)reminders.count);
        [Utils runOnMainThread:^{
            if (reminders.count <= 0) {
                NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:@"<None>" action:nil keyEquivalent:@""];
                [menu insertItem:item atIndex:start];
            }
            else {
                [reminders enumerateObjectsUsingBlock:^(EKReminder* reminder, NSUInteger i, BOOL* stop) {
                    NSMenuItem* item = [self createReminderMenuItem:reminder];
                    [menu insertItem:item atIndex:start + i];
                }];
            }
        }];
    }];
}

- (void)insertQuitMenuItem:(NSMenu*)menu {
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
}

- (NSMenuItem*)createReminderMenuItem:(EKReminder*)reminder {
    NSString* title = reminder.title;
    if (reminder.dueDateComponents != nil) {
        NSString* dateStr = [AppDelegate formatDueDate:reminder.dueDateComponents];
        if (dateStr != nil && dateStr.length > 0) {
            title = [@[title, @" (", dateStr, @")"] componentsJoinedByString:@""];
        }
    }
    else {
        NSLog(@"'%@' dueDateComponents==nil", reminder.title);
    }
    return [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
}

- (void)openRemindersPrivacyPrefs:(nullable id)sender {
    // from https://macosxautomation.com/system-prefs-links.html
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"]];
}

- (void)applicationWillTerminate:(NSNotification*)aNotification {
    // clean up status bar item
    if (self.statusItem != nil) {
        [self.statusItem.statusBar removeStatusItem:self.statusItem];
        self.statusItem.menu = nil;
        self.statusItem = nil;
    }
}

@end
