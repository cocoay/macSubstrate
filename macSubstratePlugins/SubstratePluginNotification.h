//
//  SubstratePluginNotification.h
//  macSubstratePlugins
//
//  Created by GoKu on 20/11/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SubstratePluginNotification : NSObject

@property (nonatomic, assign) BOOL enableRemoteNotify;
@property (nonatomic, strong) NSString *scKey;

+ (instancetype)sharedManager;

- (void)pushLocalNotifyTitle:(NSString *)notifyTitle
                  notifyInfo:(NSString *)notifyInfo
                  notifyType:(NSString *)notifyType;
- (void)pushRemoteNotifyTitle:(NSString *)notifyTitle
                   notifyInfo:(NSString *)notifyInfo;

@end
