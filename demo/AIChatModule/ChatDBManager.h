//
//  ChatDBManager.h
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import <Foundation/Foundation.h>
#import "ChatManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface ChatDBManager : NSObject

+ (instancetype)sharedManager;
- (BOOL)createMessageTable;
- (BOOL)insertOrUpdateMessage:(ChatMessage *)msg;
- (NSArray<ChatMessage *> *)fetchMessageListBySessionId:(NSString *)sessionId;

@end

NS_ASSUME_NONNULL_END
