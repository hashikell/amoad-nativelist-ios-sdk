//
//  ViewController.m
//  AMoAdInfeedDemo
//
//  Created by AMoAd on 2016/02/24.
//  Copyright © 2016年 AMoAd. All rights reserved.
//
#import "ViewController.h"
#import "AMoAdInfeed.h"

#pragma mark - ユーザーデータ例

@interface UserItem : NSObject
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
    //    self.iconUrl = [NSURL URLWithString:amoad.iconUrl];
    self.iconUrl = [NSURL fileURLWithPath:amoad.iconUrl]; // [TEST] ローカルファイルのURL
    self.text1 = amoad.serviceName;
    self.text2 = amoad.titleShort;
    self.text3 = amoad.titleLong;
    self.adList = amoad;
  }
  return self;
}

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

@end

#pragma mark - ViewController

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic,readwrite,weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *adCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *beginIndexLabel;
@property (weak, nonatomic) IBOutlet UILabel *intervalLabel;
@property (nonatomic,readwrite,strong) NSArray *dataArray;
@end

static NSString *const kSid1 = @"62056d310111552c000000000000000000000000000000000000000000000000";
static NSString *const kCustomScheme = @"custom:";

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // ユーザーCell
  [self.tableView registerNib:[UINib nibWithNibName:@"UserCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"UserCell"];

  // [SDK] 広告Cell  ユーザーCellと同じNibを使うことができます。
  //  [self.tableView registerNib:[UINib nibWithNibName:@"AdCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"AdCell"];

  userItemLoadQueue = dispatch_queue_create("com.amoad.sample.UserItemLoadQueue", NULL);
  iconLoadQueue = dispatch_queue_create("com.amoad.sample.IconLoadQueue", NULL);
  self.dataArray = @[];

  // [SDK] タイムアウト時間を設定する
  [AMoAdInfeed setNetworkTimeoutSeconds:5.0];

  // [SDK] 広告をロードする
  //  広告データをコールバックで返す
  [AMoAdInfeed loadWithSid:kSid1 completion:^(AMoAdList *adList, AMoAdResult result) {
    [self.adCountLabel setText:[@(adList.ads.count) stringValue]];  // LOG
    [self.beginIndexLabel setText:[@(adList.beginIndex) stringValue]];  // LOG
    [self.intervalLabel setText:[@(adList.interval) stringValue]];  // LOG

    // ユーザーデータを取得する
    [self loadUserItem:20 completion:^(NSArray<UserItem *> *userItems) {

      // 広告データを挿入する
      self.dataArray = [self insertAdList:adList userItems:userItems];

      // テーブルを再描画する
      [self.tableView reloadData];
    }];
  }];

  // PullToRefresh
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
  [self.tableView addSubview:refreshControl];
}

- (void)onRefresh:(UIRefreshControl *)refreshControl {
  [refreshControl beginRefreshing];

  [AMoAdInfeed loadWithSid:kSid1 completion:^(AMoAdList *adList, AMoAdResult result) {
    [self.adCountLabel setText:[@(adList.ads.count) stringValue]];  // LOG
    [self.beginIndexLabel setText:[@(adList.beginIndex) stringValue]];  // LOG
    [self.intervalLabel setText:[@(adList.interval) stringValue]];  // LOG

    // ユーザーデータを取得する
    [self loadUserItem:20 completion:^(NSArray<UserItem *> *userItems) {

      // 広告データを挿入する
      self.dataArray = [self insertAdList:adList userItems:userItems];

      // テーブルを再描画する
      [self.tableView reloadData];
    }];
  }];

  [refreshControl endRefreshing];
}

- (void)loadUserItem:(NSInteger)count completion:(void (^)(NSArray<UserItem *> *userItems))completion {
  dispatch_async(userItemLoadQueue, ^{
    NSDate* localNow = [NSDate dateWithTimeIntervalSinceNow:[[NSTimeZone systemTimeZone] secondsFromGMT]];
    NSMutableArray<UserItem *> *userItems = [[NSMutableArray alloc] initWithCapacity:count];
    static NSInteger dataCount = 0;
    for (NSInteger i = 0; i < count; i++) {
      UserItem *ud = [[UserItem alloc] init];
      NSString *filePath = [[NSBundle mainBundle] pathForResource:@"user" ofType:@"png"];
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

- (void)addUserItem:(NSInteger)count {
  // [SDK] 広告をロードする
  //  広告データをコールバックで返す
  [AMoAdInfeed loadWithSid:kSid1 completion:^(AMoAdList *adList, AMoAdResult result) {
    [self.adCountLabel setText:[@(adList.ads.count) stringValue]];  // LOG
    [self.beginIndexLabel setText:[@(adList.beginIndex) stringValue]];  // LOG
    [self.intervalLabel setText:[@(adList.interval) stringValue]];  // LOG

    // ユーザーデータを取得する
    [self loadUserItem:count completion:^(NSArray<UserItem *> *userItems) {

      // 広告データを挿入する
      NSArray<UserItem *> *array = [self insertAdList:adList userItems:userItems];
      self.dataArray = [self.dataArray arrayByAddingObjectsFromArray:array];

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
  cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
  UIImageView *iconView = (UIImageView *)[cell viewWithTag:200];
  UILabel *label1 = (UILabel *)[cell viewWithTag:100];
  UILabel *label2 = (UILabel *)[cell viewWithTag:101];
  UILabel *label3 = (UILabel *)[cell viewWithTag:102];

  // リサイクルされるのでクリアする
  [label1 setText:@""];
  [label2 setText:@""];
  [label3 setText:@""];

  UserItem *ud = self.dataArray[indexPath.row];

  // データを表示する
  [ud loadIcon:^(UIImage *icon) {
    iconView.image = icon;
  }];
  label1.text = ud.text1;
  label2.text = ud.text2;
  label3.text = ud.text3;

  if (ud.adList) {
    // [SDK] Impを送信する
    [ud.adList sendImpression];
  }

  // 下までスクロールしたらデータを追加する
  if (indexPath.row >= self.dataArray.count - 1) {
    [self addUserItem:20];
    [self.tableView reloadData];
  }

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES]; // 選択状態の解除をします。
  UserItem *ud = self.dataArray[indexPath.row];

  if (ud.adList) {
    // [SDK] クリック時：
    //   customSchemeに指定されたスキームの場合、handlerに遷移処理を委ねる
    [ud.adList onClickWithCustomScheme:kCustomScheme handler:^(NSString *url) {

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
