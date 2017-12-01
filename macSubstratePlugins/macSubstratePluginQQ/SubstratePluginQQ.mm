//
//  SubstratePluginQQ.m
//  macSubstratePluginQQ
//
//  Created by GoKu on 20/10/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

#import "SubstratePluginQQ.h"
#import "SubstratePluginNotification.h"

@interface SubstratePluginQQ ()

@end

@implementation SubstratePluginQQ

+ (instancetype)sharedPlugin
{
    static SubstratePluginQQ *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SubstratePluginQQ alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)handleRecallNotify:(struct RecallModel *)recallModel
                      with:(QQMessageRevokeEngine *)revokeEngine
{
    NSString *notifyTitle = @"🈲";
    
    NSString *content = [[revokeEngine getProcessor] getRecallMessageContent:recallModel];
    NSArray *json = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:NULL];
    
    if (json && [NSJSONSerialization isValidJSONObject:json]) {
        for (NSDictionary *item in json) {
            NSString *text = item[@"text"];
            NSString *notifyInfo = ((text.length > 0) ? text : @"消息撤回");
            [[SubstratePluginNotification sharedManager] pushLocalNotifyTitle:notifyTitle
                                                                   notifyInfo:notifyInfo
                                                                   notifyType:@"revoke"];
        }
        
    } else {
        NSString *notifyInfo = @"消息撤回";
        [[SubstratePluginNotification sharedManager] pushLocalNotifyTitle:notifyTitle
                                                               notifyInfo:notifyInfo
                                                               notifyType:@"revoke"];
    }
}

@end
