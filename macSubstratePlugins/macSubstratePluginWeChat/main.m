//
//  main.m
//  macSubstratePluginWeChat
//
//  Created by GoKu on 29/09/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptainHook.h"
#import "SubstratePluginWeChat.h"

CHDeclareClass(MessageService)
CHDeclareClass(MMContactsViewController)

CHMethod(2, void, MessageService, notifyAddMsgOnMainThread, id, arg1, msgData, id, arg2)
{
    CHSuper(2, MessageService, notifyAddMsgOnMainThread, arg1, msgData, arg2);
    
    [[SubstratePluginWeChat sharedPlugin] parseHongbaoMessage:(MessageData *)arg2];
    [[SubstratePluginWeChat sharedPlugin] parseKeywordMessage:(MessageData *)arg2];
}

CHMethod(1, void, MessageService, onRevokeMsg, id, arg1)
{
    [[SubstratePluginWeChat sharedPlugin] onRevokeMsg:(NSString *)arg1
                                      selfRevokeBlock:^{
                                          CHSuper(1, MessageService, onRevokeMsg, arg1);
                                      }];
}

CHMethod(1, id, MMContactsViewController, contextMenuForContactRow, id, arg1)
{
    NSMenu *menu = CHSuper(1, MMContactsViewController, contextMenuForContactRow, arg1);
    WCContactData *contact = ((MMContactListContactRowView *)arg1).displayedContact;
    if ([contact isGroupChat]) {
        NSMenuItem *item = [menu addItemWithTitle:@"Notify Keywords"
                                           action:@selector(configGroupChatContentKeyword:)
                                    keyEquivalent:@""];
        item.target = self;
    }
    return menu;
}

CHMethod(1, void, MMContactsViewController, configGroupChatContentKeyword, id, arg1)
{
    MMContactListContactRowView *rowView = [self valueForKey:@"_rowViewForContextMenu"];
    WCContactData *group = rowView.displayedContact;
    [[SubstratePluginWeChat sharedPlugin] setKeywordListForGroup:group];
}

__attribute__((constructor))
void macSubstratePluginWeChatEntry()
{
    NSLog(@"%s: hello %@ (%d), I am in :)", __FUNCTION__, [[NSBundle mainBundle] bundleIdentifier], getpid());
    
    CHLoadLateClass(MessageService);
    CHClassHook(2, MessageService, notifyAddMsgOnMainThread, msgData);
    CHClassHook(1, MessageService, onRevokeMsg);
    
    CHLoadLateClass(MMContactsViewController);
    CHClassHook(1, MMContactsViewController, configGroupChatContentKeyword);
    CHClassHook(1, MMContactsViewController, contextMenuForContactRow);
    
    [[SubstratePluginWeChat sharedPlugin] setup];
}
