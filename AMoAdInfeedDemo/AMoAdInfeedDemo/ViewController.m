//
//  ViewController.m
//  AMoAdInfeedDemo
//
//  Created by AMoAd on 2016/02/24.
//  Copyright © 2016年 AMoAd. All rights reserved.
//
#import "ViewController.h"
#import "AMoAdInfeed.h"
#import "AMoAdLogger.h"

#pragma mark - ユーザーデータ例

@interface UserItem : NSObject
@property (nonatomic,readwrite,assign) NSInteger index;
@property (nonatomic,readwrite,strong) NSURL *iconUrl;
@property (nonatomic,readwrite,copy) NSString *text1;
@property (nonatomic,readwrite,copy) NSString *text2;
@property (nonatomic,readwrite,copy) NSString *text3;
@property (nonatomic,readwrite,strong) AMoAdItem *adList;
@end

static dispatch_queue_t userItemLoadQueue;
static dispatch_queue_t iconLoadQueue;

@implementation UserItem
// AMoAdItem -> UserItem 変換
- (instancetype)initWithAMoAd:(AMoAdItem *)amoad {
  self = [super init];
  if (self) {
    self.index = -1;
    self.iconUrl = [NSURL URLWithString:amoad.iconUrl];
    self.text1 = amoad.serviceName;
    self.text2 = amoad.titleShort;
    self.text3 = amoad.titleLong;
    self.adList = amoad;
  }
  return self;
}

// ユーザーデータと広告で同じ画像ロードの仕組みを使う
- (void)loadIcon:(void (^)(UIImage *icon))completion {
  dispatch_async(iconLoadQueue, ^{
    UIImage *icon = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:self.iconUrl];
    NSURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (!error && response && data) {
      icon = [UIImage imageWithData:data];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(icon);
    });
  });
}

// ネットワークまたはローカルキャッシュからユーザーデータを読み込む
+ (void)loadUserItem:(NSInteger)count completion:(void (^)(NSArray<UserItem *> *userItems))completion {
  dispatch_async(userItemLoadQueue, ^{
    NSDate* localNow = [NSDate dateWithTimeIntervalSinceNow:[[NSTimeZone systemTimeZone] secondsFromGMT]];
    NSMutableArray<UserItem *> *userItems = [[NSMutableArray alloc] initWithCapacity:count];
    static NSInteger dataCount = 0;
    for (NSInteger i = 0; i < count; i++) {
      UserItem *ud = [[UserItem alloc] init];
      NSString *filePath = [[NSBundle mainBundle] pathForResource:@"user" ofType:@"png"];
      ud.index = dataCount;
      ud.iconUrl = [NSURL fileURLWithPath:filePath];
      ud.text1 = [NSString stringWithFormat:@"タイトル%ld", (long)dataCount];
      ud.text2 = [NSString stringWithFormat:@"サブタイトル%ld", (long)dataCount];
      ud.text3 = [NSString stringWithFormat:@"%@", localNow];
      dataCount++;
      [userItems addObject:ud];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(userItems);
    });
  });
}

+ (UIImage *)setNumber:(NSInteger)number toImage:(UIImage *)image {
  NSString *text = [NSString stringWithFormat:@"%ld", (long)number];

  UIFont *font = [UIFont boldSystemFontOfSize:32];
  CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);

  UIGraphicsBeginImageContext(image.size);

  [image drawInRect: imageRect];

  CGRect textRect  = CGRectMake(5, 5, image.size.width - 5, image.size.height - 5);
  NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
  NSDictionary *textFontAttributes =
  @{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [UIColor whiteColor],
    NSParagraphStyleAttributeName: textStyle
    };
  [text drawInRect:textRect withAttributes: textFontAttributes];

  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return newImage;
}

@end

#pragma mark - ViewController

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic,readwrite,weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *adCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *beginIndexLabel;
@property (weak, nonatomic) IBOutlet UILabel *intervalLabel;
@property (nonatomic,readwrite,strong) NSArray<UserItem *> *dataArray;
@end

static NSString *const kSid1 = @"62056d310111552c000000000000000000000000000000000000000000000000";
static const NSInteger kDataCount = 20;

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // [SDK] ログ出力を設定する
  [AMoAdLogger sharedLogger].logging = YES;
  [AMoAdLogger sharedLogger].trace = YES;

  // ユーザーCell
  [self.tableView registerNib:[UINib nibWithNibName:@"UserCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"UserCellId"];

  // [SDK] 広告Cell  ユーザーCellと同じNibを使うことができます。
  //  [self.tableView registerNib:[UINib nibWithNibName:@"AdCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"AdCell"];

  userItemLoadQueue = dispatch_queue_create("com.amoad.sample.UserItemLoadQueue", NULL);
  iconLoadQueue = dispatch_queue_create("com.amoad.sample.IconLoadQueue", NULL);

  // [SDK] タイムアウト時間を設定する：デフォルトは30,000ミリ秒
  [AMoAdInfeed setNetworkTimeoutMillis:5000];

  // PullToRefresh
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
  [self.tableView addSubview:refreshControl];

  [self onRefresh:refreshControl];
}

- (void)onRefresh:(UIRefreshControl *)refreshControl {
  [refreshControl beginRefreshing];

  [self addUserItem:kDataCount original:@[]];

  [refreshControl endRefreshing];
}

- (NSArray<UserItem *> *)insertAdList:(AMoAdList *)adList userItems:(NSArray<UserItem *> *)userItems {
  NSMutableArray<UserItem *> *array = [[NSMutableArray<UserItem *> alloc] initWithArray:userItems];

  // 広告データを挿入する
  NSInteger adIdx = 0;
  for (NSInteger i = 0; i < userItems.count; i++) {
    if (i == adList.beginIndex || (i > adList.beginIndex && (i - adList.beginIndex) % adList.interval == 0)) {
      UserItem *ud = [[UserItem alloc] initWithAMoAd:adList.ads[adIdx++]];
      [array insertObject:ud atIndex:i];
    }
    if (adIdx >= adList.ads.count) {
      break;
    }
  }

  return array;
}

- (void)addUserItem:(NSInteger)count original:(NSArray<UserItem *> *)original {
  // [SDK] 広告をロードする
  //  広告データをコールバックで返す
  [AMoAdInfeed loadWithSid:kSid1 completion:^(AMoAdList *adList, AMoAdResult result) {
    [self.adCountLabel setText:[@(adList.ads.count) stringValue]];  // LOG
    [self.beginIndexLabel setText:[@(adList.beginIndex) stringValue]];  // LOG
    [self.intervalLabel setText:[@(adList.interval) stringValue]];  // LOG

    // ユーザーデータを取得する
    [UserItem loadUserItem:count completion:^(NSArray<UserItem *> *userItems) {

      if (result == AMoAdResultSuccess) {
        // 広告データを挿入する
        NSArray<UserItem *> *array = [self insertAdList:adList userItems:userItems];
        self.dataArray = [original arrayByAddingObjectsFromArray:array];
      } else {
        self.dataArray = [original arrayByAddingObjectsFromArray:userItems];
      }

      // テーブルを再描画する
      [self.tableView reloadData];
    }];
  }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  // ユーザーCell
  cell = [tableView dequeueReusableCellWithIdentifier:@"UserCellId" forIndexPath:indexPath];
  UIImageView *iconView = (UIImageView *)[cell viewWithTag:200];
  UILabel *label1 = (UILabel *)[cell viewWithTag:100];
  UILabel *label2 = (UILabel *)[cell viewWithTag:101];
  UILabel *label3 = (UILabel *)[cell viewWithTag:102];

  // データを表示する
  UserItem *ud = self.dataArray[indexPath.row];
  label1.text = ud.text1;
  label2.text = ud.text2;
  label3.text = ud.text3;
  iconView.image = nil;

  [ud loadIcon:^(UIImage *icon) {
    if ([label1.text isEqualToString:ud.text1] &&
        [label2.text isEqualToString:ud.text2] &&
        [label3.text isEqualToString:ud.text3] &&
        iconView.image == nil) {  // リサイクルされていないか確認する
      if (ud.index >= 0) {
        iconView.image = [UserItem setNumber:ud.index toImage:icon];  // ユーザーアイコンに番号を付ける
      } else {
        iconView.image = icon;
      }
    } else {
      NSLog(@"画像ロード中にViewがリサイクルされた（label1: %@ -> %@）", ud.text1, label1.text);
    }
  }];

  if (ud.adList) {
    // [SDK] Impを送信する
    [ud.adList sendImpression];
  }

  // 下までスクロールしたらデータを追加する
  if (indexPath.row >= self.dataArray.count - 1) {
    [self addUserItem:kDataCount original:self.dataArray];
  }

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択状態の解除をします。
  UserItem *ud = self.dataArray[indexPath.row];

  if (ud.adList) {
    // [SDK] クリック時： handlerに遷移処理を委ねる
    [ud.adList onClickWithHandler:^(NSString *url) {

      UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:@"広告クリック"
                                          message:[NSString stringWithFormat:@"URL: %@", url]
                                   preferredStyle:UIAlertControllerStyleAlert];

      // addActionした順に左から右にボタンが配置されます
      [alertController addAction:[UIAlertAction actionWithTitle:@"はい" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // otherボタンが押された時の処理
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
      }]];
      [alertController addAction:[UIAlertAction actionWithTitle:@"いいえ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // cancelボタンが押された時の処理
      }]];

      [self presentViewController:alertController animated:YES completion:nil];
    }];
  }
}

@end
