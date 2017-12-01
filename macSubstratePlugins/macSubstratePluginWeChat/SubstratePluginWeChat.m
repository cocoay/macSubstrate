//
//  SubstratePluginWeChat.m
//  macSubstratePluginWeChat
//
//  Created by GoKu on 11/10/2017.
//  Copyright © 2017 GoKuStudio. All rights reserved.
//

#import "SubstratePluginWeChat.h"
#import "SubstratePluginNotification.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <AppKit/AppKit.h>

#define kKeywordListConfig  @"SubstratePluginKeywordListConfig"

@interface SubstratePluginWeChat ()

@property (nonatomic, strong) NSMutableDictionary *keywordListConfig;

@property (nonatomic, strong) NSMenuItem *itemEnableRemoteNotify;
@property (nonatomic, strong) NSMenuItem *itemServerChan;

@end

@implementation SubstratePluginWeChat

+ (instancetype)sharedPlugin
{
    static SubstratePluginWeChat *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SubstratePluginWeChat alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self readKeywordListConfig];
    }
    return self;
}

- (void)setup
{
    NSMenu *appMenu = [NSApp mainMenu];
    if ([appMenu itemWithTitle:@"macSubstrate"]) {
        return;
    }
    
    NSMenu *pluginMenu = [[NSMenu alloc] initWithTitle:@"macSubstrate"];
    pluginMenu.autoenablesItems = NO;
    
    self.itemEnableRemoteNotify = [[NSMenuItem alloc] init];
    self.itemEnableRemoteNotify.title = @"Enable Server Chan Notification";
    self.itemEnableRemoteNotify.target = self;
    self.itemEnableRemoteNotify.action = @selector(onClickPluginMenuEnableRemoteNotify:);
    self.itemEnableRemoteNotify.state = [SubstratePluginNotification sharedManager].enableRemoteNotify ? NSOnState : NSOffState;
    [pluginMenu addItem:self.itemEnableRemoteNotify];
    
    self.itemServerChan = [[NSMenuItem alloc] init];
    self.itemServerChan.title = @"Config Server Chan";
    self.itemServerChan.target = self;
    self.itemServerChan.action = @selector(onClickPluginMenuServerChan:);
    self.itemServerChan.enabled = [SubstratePluginNotification sharedManager].enableRemoteNotify;
    [pluginMenu addItem:self.itemServerChan];
    
    NSMenuItem *pluginMenuItem = [[NSMenuItem alloc] init];
    pluginMenuItem.title = @"macSubstrate";
    pluginMenuItem.submenu = pluginMenu;
    [appMenu insertItem:pluginMenuItem atIndex:appMenu.numberOfItems-1];
}

- (void)onClickPluginMenuEnableRemoteNotify:(id)sender
{
    BOOL newState = ![SubstratePluginNotification sharedManager].enableRemoteNotify;
    
    self.itemEnableRemoteNotify.state = newState ? NSOnState : NSOffState;
    self.itemServerChan.enabled = newState;
    
    [SubstratePluginNotification sharedManager].enableRemoteNotify = newState;
}

- (void)onClickPluginMenuServerChan:(id)sender
{
    NSString *scKey = [SubstratePluginNotification sharedManager].scKey;
    if (scKey.length <= 0) {
        scKey = @"";
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = @"Config Server Chan";
    alert.informativeText = @"Please input your SCKey to config Server Chan notification.";
    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    textField.cell.scrollable = YES;
    textField.cell.usesSingleLineMode = YES;
    textField.stringValue = scKey;
    alert.accessoryView = textField;
    [alert beginSheetModalForWindow:[NSApp mainWindow]
                  completionHandler:^(NSModalResponse returnCode) {
                      NSString *scKey = [((NSTextField *)alert.accessoryView).stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                      [SubstratePluginNotification sharedManager].scKey = scKey;
                  }];
}

- (void)parseHongbaoMessage:(MessageData *)message
{
    if (!message) {
        return;
    }
    
    if (message.messageType != 49) {
        return;
    }
    if ([message.msgContent rangeOfString:@"wxapp.tenpay.com"].location == NSNotFound) {
        return;
    }
    if (![message isChatRoomMessage]) {
        return;
    }
    if ([message isSendFromSelf]) {
        return;
    }
    
    NSString *notifyTitle = @"红包";
    WCContactData *contact = [objc_getClass("WCContactData") GetContactWithUserName:[message getChatNameForCurMsg]];
    if (contact) {
        notifyTitle = [NSString stringWithFormat:@"%@: %@", notifyTitle, [contact getGroupDisplayName]];
    }
    NSString *notifyInfo = [self matchStringWithPattern:@"<title><!\\[CDATA\\[(.*?)\\]\\]><\\/title>" inString:message.msgContent];
    
    [[SubstratePluginNotification sharedManager] pushLocalNotifyTitle:notifyTitle
                                                           notifyInfo:notifyInfo
                                                           notifyType:@"hongbao"];
    [[SubstratePluginNotification sharedManager] pushRemoteNotifyTitle:notifyTitle
                                                            notifyInfo:notifyInfo];
}

- (void)parseKeywordMessage:(MessageData *)message
{
    if (!message) {
        return;
    }
    
    if (![message isChatRoomMessage]) {
        return;
    }
    if (![self.keywordListConfig.allKeys containsObject:message.fromUsrName]) {
        return;
    }
    if ([message isSendFromSelf]) {
        return;
    }
    
    BOOL keywordMatched = NO;
    NSString *keywordList = [self getKeywordListForGroup:message.fromUsrName];
    NSArray *list = [keywordList componentsSeparatedByString:@";"];
    for (NSString *keyword in list) {
        if ((keyword.length > 0) &&
            ([message.msgContent rangeOfString:keyword].location != NSNotFound)) {
            keywordMatched = YES;
            break;
        }
    }
    if (!keywordMatched) {
        return;
    }
    
    NSString *notifyTitle = @"关键字";
    WCContactData *contact = [objc_getClass("WCContactData") GetContactWithUserName:[message getChatNameForCurMsg]];
    if (contact) {
        notifyTitle = [NSString stringWithFormat:@"%@: %@", notifyTitle, [contact getGroupDisplayName]];
    }
    NSString *notifyInfo = message.msgContent;
    NSUInteger location = [notifyInfo rangeOfString:@":"].location;
    if (location != NSNotFound) {
        notifyInfo = [[notifyInfo substringFromIndex:location+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    [[SubstratePluginNotification sharedManager] pushLocalNotifyTitle:notifyTitle
                                                           notifyInfo:notifyInfo
                                                           notifyType:@"keyword"];
}

- (void)readKeywordListConfig
{
    self.keywordListConfig = [NSMutableDictionary dictionary];
    
    NSDictionary *config = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kKeywordListConfig];
    [config enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *groupName = key;
        NSString *keywordList = obj;
        if ((groupName.length > 0) && (keywordList.length > 0)) {
            [self.keywordListConfig setValue:keywordList forKey:groupName];
        }
    }];
    
    [self writeKeywordListConfig];
}

- (void)writeKeywordListConfig
{
    if (self.keywordListConfig) {
        [[NSUserDefaults standardUserDefaults] setValue:self.keywordListConfig forKey:kKeywordListConfig];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setKeywordListForGroup:(WCContactData *)group
{
    NSString *groupName = group.m_nsUsrName;
    if (groupName.length <= 0) {
        return;
    }
    
    NSString *displayName = [group getGroupDisplayName];
    NSString *keywordList = [self getKeywordListForGroup:groupName];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = displayName;
        alert.informativeText = @"Please input your keywords seperated by \";\".";
        NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
        textField.cell.scrollable = YES;
        textField.cell.usesSingleLineMode = YES;
        textField.stringValue = keywordList;
        alert.accessoryView = textField;
        [alert beginSheetModalForWindow:[NSApp mainWindow]
                      completionHandler:^(NSModalResponse returnCode) {
                          NSString *keywordList = [((NSTextField *)alert.accessoryView).stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                          if (keywordList.length > 0) {
                              [self.keywordListConfig setValue:keywordList forKey:groupName];
                          } else {
                              [self.keywordListConfig removeObjectForKey:groupName];
                          }
                          [self writeKeywordListConfig];
                      }];
    });
}

- (NSString *)getKeywordListForGroup:(NSString *)groupName
{
    if (groupName.length <= 0) {
        return @"";
    }
    
    NSString *keywordList = [self.keywordListConfig valueForKey:groupName];
    return (keywordList.length > 0) ? keywordList : @"";
}

- (void)onRevokeMsg:(NSString *)revokeMsg
    selfRevokeBlock:(void(^)(void))selfRevokeBlock
{
    if (!revokeMsg) {
        return;
    }
    
    NSString *newmsgid = [self matchStringWithPattern:@"<newmsgid>(.*?)<\\/newmsgid>" inString:revokeMsg];
    NSString *session = [self matchStringWithPattern:@"<session>(.*?)<\\/session>" inString:revokeMsg];
    NSString *replacemsg = [self matchStringWithPattern:@"<replacemsg><!\\[CDATA\\[(.*?)\\]\\]><\\/replacemsg>" inString:revokeMsg];
    
    NSString *notifyTitle = @"防撤回";
    NSString *notifyInfo = replacemsg;
    
    MessageService *messageService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("MessageService") class]];
    MessageData *message = [messageService GetMsgData:session svrId:newmsgid.longLongValue];
    if (message) {
        if ([message isSendFromSelf]) {
            selfRevokeBlock();
            return;
        }
        
        MessageData *localMsg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
        localMsg.fromUsrName = message.fromUsrName;
        localMsg.toUsrName = message.toUsrName;
        localMsg.msgContent = (replacemsg.length > 0) ? [@"🈲 " stringByAppendingString:replacemsg] : @"🈲";
        localMsg.msgStatus = 0x4;
        localMsg.msgCreateTime = message.msgCreateTime;
        [messageService AddRevokePromptMsg:session msgData:localMsg];
        
        WCContactData *contact = [objc_getClass("WCContactData") GetContactWithUserName:[message getChatNameForCurMsg]];
        NSString *fromUserName = ([message isChatRoomMessage] ? [contact getGroupDisplayName] : [contact getContactDisplayName]);
        notifyTitle = [NSString stringWithFormat:@"%@: %@", notifyTitle, fromUserName];
    }
    
    [[SubstratePluginNotification sharedManager] pushLocalNotifyTitle:notifyTitle
                                                           notifyInfo:notifyInfo
                                                           notifyType:@"revoke"];
}

- (NSString *)matchStringWithPattern:(NSString *)pattern inString:(NSString *)inString
{
    if (!pattern || !inString) {
        return nil;
    }
    
    NSString *matchedString = nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    NSTextCheckingResult *result = [regex matchesInString:inString options:0 range:NSMakeRange(0, inString.length)].firstObject;
    if (result.numberOfRanges >= 2) {
        matchedString = [inString substringWithRange:[result rangeAtIndex:1]];
    }
    
    return matchedString;
}

@end
