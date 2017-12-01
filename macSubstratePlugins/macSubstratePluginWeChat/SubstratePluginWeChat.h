//
//  SubstratePluginWeChat.h
//  macSubstratePluginWeChat
//
//  Created by GoKu on 11/10/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WeChatHeader.h"

@interface SubstratePluginWeChat : NSObject

+ (instancetype)sharedPlugin;

- (void)setup;

- (void)parseHongbaoMessage:(MessageData *)message;
- (void)parseKeywordMessage:(MessageData *)message;
- (void)setKeywordListForGroup:(WCContactData *)group;
- (void)onRevokeMsg:(NSString *)revokeMsg
    selfRevokeBlock:(void(^)(void))selfRevokeBlock;

@end
