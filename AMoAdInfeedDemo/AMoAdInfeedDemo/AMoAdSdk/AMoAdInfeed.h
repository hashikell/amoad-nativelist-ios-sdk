//
//  AMoAdInfeed.h
//
//  Created by AMoAd on 2016/02/19.
//
#import <Foundation/Foundation.h>
#import "AMoAd.h"
#import "AMoAdList.h"

/// ネイティブリスト広告
@interface AMoAdInfeed : NSObject

/// ネットワークタイムアウト時間を設定する（デフォルトは30.0秒）
+ (void)setTimeoutInterval:(NSTimeInterval)interval;

/// 広告をロードする
/// @param sid 管理画面から取得した64文字の英数字
/// @param completion 広告オブジェクト配列と結果を受け取るBlock
+ (void)loadWithSid:(NSString *)sid
         completion:(void (^)(AMoAdList *adList, AMoAdResult result))completion;


/// 開発用
+ (void)loadWithSid:(NSString *)sid
         completion:(void (^)(AMoAdList *adList, AMoAdResult result))completion
             option:(NSDictionary *)option;

/// 使用不可
- (instancetype)init __attribute__((unavailable("This method is not available.")));

@end
