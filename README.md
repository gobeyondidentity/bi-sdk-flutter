<p align="center">
   <br/>
   <a href="https://developers.beyondidentity.com" target="_blank"><img src="https://user-images.githubusercontent.com/238738/178780350-489309c5-8fae-4121-a20b-562e8025c0ee.png" width="150px" ></a>
   <h3 align="center">Beyond Identity</h3>
   <p align="center">Universal Passkeys for Developers</p>
   <p align="center">
   All devices. Any protocol. Zero shared secrets.
   </p>
</p>

# Beyond Identity Flutter SDK

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

### Embedded SDK

Goodbye, passwords! The Beyond Identity SDK for Flutter is a wrapper around our native SDKs ([Android](https://github.com/gobeyondidentity/bi-sdk-android) and [iOS](https://github.com/gobeyondidentity/bi-sdk-swift)), which allow you to embed the Passwordless experience into your product. A set of functions are provided to you through the Embedded namespace. This SDK supports OIDC and OAuth 2.0.

## Installation

### Pub.Dev

Add the Beyond Identity Embedded SDK to your dependencies

```yaml
dependencies:
  bi_sdk_flutter: x.y.z
```

and run an implicit `flutter pub get`

### Update Android

Please make sure your `android/build.gradle` supports `minSdkVersion` 26 or later.

```
buildscript {
  ext {
    minSdkVersion = 26
  }
}
```

### Update iOS

Please make sure your project supports "minimum deployment target" 15.1 or later.
In your `ios/Podfile` set:

```sh
platform :ios, '15.1'
```

## Usage

Check out the [Developer Documentation](https://developer.beyondidentity.com) and the [SDK API Documentation](https://gobeyondidentity.github.io/bi-sdk-flutter/) for more information.

### Setup

First, before calling the Embedded functions, make sure to initialize the SDK.

```dart
import 'package:bi_sdk_flutter/embeddedsdk.dart';

EmbeddedSdk.initialize(
    String biometricAskPrompt,
    List<String>? allowedDomains, /* Optional */
    Future<Function>? logger, /* Optional */
)
```

For example:

```dart
EmbeddedSdk.initialize("Gimmie your biometrics", logger: EmbeddedSdk.enableLogger());
```

## Example App

To run the Android example app

1. Run `flutter pub get` from the root of the repo
2. Run `flutter run` from the example directory or use Android Studio. Make sure an Android device is running.

To run the iOS example app

1. Run `flutter pub get` from the root of the repo
2. Run `pod install --repo-update` from `example/ios` directory
3. Run `flutter run` from the example directory or use XCode.
