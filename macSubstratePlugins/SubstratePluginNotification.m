//
//  SubstratePluginNotification.m
//  macSubstratePlugins
//
//  Created by GoKu on 20/11/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

#import "SubstratePluginNotification.h"

#define kEnableRemoteNotify @"SubstratePluginNotificationEnableRemoteNotify"
#define kServerChanKey      @"SubstratePluginNotificationServerChanKey"

@interface SubstratePluginNotification () <NSUserNotificationCenterDelegate>

@property (nonatomic, weak) id<NSUserNotificationCenterDelegate> originalDelegate;

@end

@implementation SubstratePluginNotification

+ (instancetype)sharedManager
{
    static SubstratePluginNotification *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SubstratePluginNotification alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _originalDelegate = [[NSUserNotificationCenter defaultUserNotificationCenter] delegate];
        
        _enableRemoteNotify = [[NSUserDefaults standardUserDefaults] boolForKey:kEnableRemoteNotify];
        _scKey = [[NSUserDefaults standardUserDefaults] stringForKey:kServerChanKey];

    }
    return self;
}

- (void)setEnableRemoteNotify:(BOOL)enableRemoteNotify
{
    _enableRemoteNotify = enableRemoteNotify;
    
    [[NSUserDefaults standardUserDefaults] setValue:@(_enableRemoteNotify) forKey:kEnableRemoteNotify];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setScKey:(NSString *)scKey
{
    _scKey = scKey;
    
    if (_scKey.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:_scKey forKey:kServerChanKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kServerChanKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)pushLocalNotifyTitle:(NSString *)notifyTitle
                  notifyInfo:(NSString *)notifyInfo
                  notifyType:(NSString *)notifyType
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = notifyTitle;
        notification.informativeText = notifyInfo;
        notification.hasActionButton = YES;
        notification.soundName = NSUserNotificationDefaultSoundName;
        notification.userInfo = @{NSStringFromClass([SubstratePluginNotification class]): (notifyType ?: @"")};
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    });
}

- (void)pushRemoteNotifyTitle:(NSString *)notifyTitle
                   notifyInfo:(NSString *)notifyInfo
{
    if (!self.enableRemoteNotify || (self.scKey.length <= 0)) {
        return;
    }
    
    NSString *text = [[NSString stringWithFormat:@"%@ %@", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle], notifyTitle] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *desp = [notifyInfo stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *url = [NSString stringWithFormat:@"https://sc.ftqq.com/%@.send?text=%@&desp=%@", self.scKey, text, desp];
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url]] resume];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    if ([notification.userInfo valueForKey:NSStringFromClass([SubstratePluginNotification class])]) {
        return YES;
        
    } else {
        if ([self.originalDelegate respondsToSelector:@selector(userNotificationCenter:shouldPresentNotification:)]) {
            return [self.originalDelegate userNotificationCenter:center shouldPresentNotification:notification];
        } else {
            return NO;
        }
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    if ([self.originalDelegate respondsToSelector:@selector(userNotificationCenter:didDeliverNotification:)]) {
        [self.originalDelegate userNotificationCenter:center didDeliverNotification:notification];
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([self.originalDelegate respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)]) {
        [self.originalDelegate userNotificationCenter:center didActivateNotification:notification];
    }
}

@end
