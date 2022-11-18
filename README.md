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

### Embedded

The Embedded SDK is a holistic SDK solution offering the entire experience embedded in your product. Users will not need
to download the Beyond Identity Authenticator.

## Installation

### Pub.Dev

Add the Beyond Identity Embedded SDK to your dependencies

```yaml
dependencies:
  bi_sdk_flutter: x.y.z
```

and run an implicit `flutter pub get`

## Usage

Check out the [documentation](https://developer.beyondidentity.com) for more information.

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

Please make sure your project supports "minimum deployment target" 13.0 or later.
In your `ios/Podfile` set:

```sh
platform :ios, '13.0'
```

### Setup

First, before calling the Embedded functions, make sure to initialize the SDK.

<!-- javascript is used here since flutter is not available and dart doesn't highlight at all. -->
```javascript
import 'package:bi_sdk_flutter/embeddedsdk.dart';

Embeddedsdk.initialize(
    String biometricPrompt,
    bool enableLogging,
    List<String>? allowedDomains, /* Optional */
)
```

### Example app
To run the Android example app
1. Run `flutter pub get` from the root of the repo
2. Run `flutter run` from the example directory or use Android Studio. Make sure an Android device is running.

To run the iOS example app
1. Run `flutter pub get` from the root of the repo
2. Run `pod install --repo-update` from `example/ios` directory
3. Run `flutter run` from the example directory or use XCode.
