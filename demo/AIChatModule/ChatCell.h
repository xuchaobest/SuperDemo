//
//  ChatCell.h
//  demo
//
//  Created by RichardX on 2026/8/3.
//

#import <UIKit/UIKit.h>
@class ChatMessage;
NS_ASSUME_NONNULL_BEGIN

@interface ChatCell : UICollectionViewCell

- (void)configWithMessage:(ChatMessage *)msg;

@end

NS_ASSUME_NONNULL_END
