<div align="center">
<img width="172" height="61" src="http://www.amoad.com/images/logo.png">
</div>

# AMoAd Infeed Demo for iOS ver 4.7.4

<img width="160" height="284" src="docs/res/ScreenShot01.png">
<img width="320" src="docs/res/ScreenShot03.png">

## Introduction

アプリのコンテンツに広告画像とテキストを表示することができるネイティブ広告です。
表示開始位置と間隔を管理画面から設定することができます。

## Requirements

iOS 7.0 or later

## Installing

[ZIPをダウンロード](https://github.com/amoad/amoad-nativelist-ios-sdk/archive/master.zip)

## Usage

管理画面から取得したsidをViewController.mのkSidに設定する。

```objc
// [SDK] 管理画面から取得したsidを入力してください
static NSString *const kSid = @"62056d310111552c000000000000000000000000000000000000000000000000";
```

## API

[AMoAd Infeed API](AMoAdInfeedDemo/AMoAdInfeedDemo/AMoAdSdk/AMoAdInfeed.h)

[AMoAd List API](AMoAdInfeedDemo/AMoAdInfeedDemo/AMoAdSdk/AMoAdList.h)

[AMoAd Item API](AMoAdInfeedDemo/AMoAdInfeedDemo/AMoAdSdk/AMoAdItem.h)

[AMoAd Logger API](AMoAdInfeedDemo/AMoAdInfeedDemo/AMoAdSdk/AMoAdLogger.h) 
 ... [ログ出力設定](https://github.com/amoad/amoad-ios-sdk/wiki/Logger)


## Project Settings

### 設定例

[ATS (App Transport Security) を抑制する](https://github.com/amoad/amoad-ios-sdk/wiki/Install#34-ats-app-transport-security-を抑制する)

<img width="640" src="docs/res/ScreenShot04.png">
