//
//  WeChatHeader.h
//  macSubstratePluginWeChat
//
//  Created by GoKu on 10/10/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

#ifndef WeChatHeader_h
#define WeChatHeader_h

#import <Cocoa/Cocoa.h>

@interface MMServiceCenter : NSObject
+ (instancetype)defaultCenter;
- (id)getService:(Class)service;
@end

@interface MessageService : NSObject
- (void)notifyAddMsgOnMainThread:(id)arg1 msgData:(id)arg2;
- (void)onRevokeMsg:(id)arg1;
- (id)GetMsgData:(id)arg1 svrId:(unsigned long long)arg2;
- (void)AddRevokePromptMsg:(id)arg1 msgData:(id)arg2;
- (void)AddLocalMsg:(id)arg1 msgData:(id)arg2;
@end

@interface MessageData : NSObject
@property (nonatomic, assign) unsigned int messageType;
@property (nonatomic, strong) NSString *fromUsrName;
@property (nonatomic, strong) NSString *toUsrName;
@property (nonatomic, strong) NSString *msgContent;
@property (nonatomic, assign) unsigned int msgStatus;
@property (nonatomic, assign) unsigned int msgCreateTime;
- (instancetype)initWithMsgType:(long long)arg1;
- (NSString *)getChatNameForCurMsg;
- (BOOL)isChatRoomMessage;
- (BOOL)isSendFromSelf;
@end

@interface WCContactData : NSObject
@property (nonatomic, strong) NSString *m_nsUsrName;
+ (instancetype)GetContactWithUserName:(NSString *)arg1;
- (NSString *)getGroupDisplayName;
- (NSString *)getContactDisplayName;
- (BOOL)isGroupChat;
@end

@interface MMContactListContactRowView : NSView
@property (nonatomic, strong) WCContactData *displayedContact;
@end

@interface MMContactsViewController : NSViewController
- (id)contextMenuForContactRow:(id)arg1;
- (void)configGroupChatContentKeyword:(id)arg1;
@end

#endif /* WeChatHeader_h */
