//
//  ChatDBManager.m
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import "ChatDBManager.h"
#import <sqlite3.h>

static NSString *const DB_NAME = @"chat_stream.db";

@interface ChatDBManager ()
@property (nonatomic, assign) sqlite3 *db;
@property (nonatomic, copy) NSString *dbPath;
@end

@implementation ChatDBManager

+ (instancetype)sharedManager {
    static ChatDBManager *ins;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ins = [[self alloc] init];
    });
    return ins;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        self.dbPath = [docPath stringByAppendingPathComponent:DB_NAME];
        [self openDatabase];
    }
    return self;
}

- (BOOL)openDatabase {
    int rc = sqlite3_open(self.dbPath.UTF8String, &_db);
    if (rc != SQLITE_OK) {
        NSLog(@"数据库打开失败：%s", sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

- (BOOL)createMessageTable {
    const char *sql =
    "CREATE TABLE IF NOT EXISTS chat_message("
    "id INTEGER PRIMARY KEY AUTOINCREMENT,"
    "message_id TEXT UNIQUE,"
    "session_id TEXT,"
    "sender_type INTEGER,"
    "ai_status INTEGER,"
    "full_content TEXT,"
    "delta_content TEXT,"
    "timestamp REAL);";
    
    char *errMsg = NULL;
    int rc = sqlite3_exec(self.db, sql, NULL, NULL, &errMsg);
    if (rc != SQLITE_OK) {
        NSLog(@"建表失败: %s", errMsg);
        sqlite3_free(errMsg);
        return NO;
    }
    return YES;
}

- (BOOL)insertOrUpdateMessage:(ChatMessage *)msg {
    const char *sql =
    "INSERT OR REPLACE INTO chat_message "
    "(message_id,session_id,sender_type,ai_status,full_content,delta_content,timestamp) "
    "VALUES (?,?,?,?,?,?,?);";
    
    sqlite3_stmt *stmt;
    int rc = sqlite3_prepare_v2(self.db, sql, -1, &stmt, NULL);
    if (rc != SQLITE_OK) return NO;

    sqlite3_bind_text(stmt, 1, msg.messageId.UTF8String, -1, NULL);
    sqlite3_bind_text(stmt, 2, msg.sessionId.UTF8String, -1, NULL);
    sqlite3_bind_int(stmt, 3, (int)msg.senderType);
    sqlite3_bind_int(stmt, 4, (int)msg.aiStatus);
    sqlite3_bind_text(stmt, 5, msg.fullContent.UTF8String, -1, NULL);
    sqlite3_bind_text(stmt, 6, msg.deltaContent.UTF8String, -1, NULL);
    sqlite3_bind_double(stmt, 7, msg.timestamp);

    rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE;
}

- (NSArray<ChatMessage *> *)fetchMessageListBySessionId:(NSString *)sessionId {
    NSMutableArray *result = [NSMutableArray array];
    const char *sql = "SELECT message_id,sender_type,ai_status,full_content,delta_content,timestamp FROM chat_message WHERE session_id = ? ORDER BY timestamp ASC;";
    sqlite3_stmt *stmt;
    
    int rc = sqlite3_prepare_v2(self.db, sql, -1, &stmt, NULL);
    if (rc != SQLITE_OK) return result;
    
    sqlite3_bind_text(stmt, 1, sessionId.UTF8String, -1, NULL);
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        ChatMessage *msg = [[ChatMessage alloc] init];
        msg.messageId = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)];
        msg.senderType = sqlite3_column_int(stmt, 1);
        msg.aiStatus = sqlite3_column_int(stmt, 2);
        msg.fullContent = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 3)];
        msg.deltaContent = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 4)];
        msg.timestamp = sqlite3_column_double(stmt, 5);
        msg.sessionId = sessionId;
        [result addObject:msg];
    }
    sqlite3_finalize(stmt);
    return result;
}

- (void)dealloc {
    if (_db) {
        sqlite3_close(_db);
    }
}
@end
