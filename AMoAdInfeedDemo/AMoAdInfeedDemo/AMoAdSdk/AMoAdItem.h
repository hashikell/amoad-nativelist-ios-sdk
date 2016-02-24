//
//  AMoAdItem.h
//  AMoAd
//
//  Created by AMoAd on 2016/02/24.
//
//

#import <Foundation/Foundation.h>

/// 広告オブジェクト
@interface AMoAdItem : NSObject

/// アイコン画像URL
@property (nonatomic,readwrite,copy) NSString *iconUrl;

/// メイン画像URL
@property (nonatomic,readwrite,copy) NSString *imageUrl;

/// ショートテキスト
@property (nonatomic,readwrite,copy) NSString *titleShort;

/// ロングテキスト
@property (nonatomic,readwrite,copy) NSString *titleLong;

/// サービス名
@property (nonatomic,readwrite,copy) NSString *serviceName;

/// 遷移先URL
@property (nonatomic,readwrite,copy) NSString *link;

/// 遷移先URL（URLエンコードされたもの）
@property (nonatomic,readwrite,copy) NSString *linkEncode;

/// 広告表示時に呼び出す
- (void)sendImpression;

/// クリック時に呼び出す
- (void)onClick;

/// クリック時に呼び出す（カスタムURLスキームをハンドリングする）
- (void)onClickWithCustomScheme:(NSString *)scheme
                        handler:(void (^)(NSString *url))handler;

@end
