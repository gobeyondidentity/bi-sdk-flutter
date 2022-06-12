<img src="https://user-images.githubusercontent.com/238738/173244201-e403272c-fa59-4122-91a2-eba4614b8081.svg" width="300px">

# Beyond Identity Flutter SDK

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

### Embedded

The Embedded SDK is a holistic SDK solution offering the entire experience embedded in your product. Users will not need
to download the Beyond Identity Authenticator.

## Installation

Add the Beyond Identity Embedded SDK to your dependencies

```yaml
dependencies:
  embeddedsdk: x.y.z
```

and run an implicit `flutter pub get`

## Usage
Check out the [documentation](https://developer.beyondidentity.com) for more information.

### Example app
To run the Android example app
1. Run `flutter pub get` from the root of the repo
2. Run `flutter run` from the example directory or use Android Studio. Make sure an Android device is running.

To run the iOS example app
1. Run `flutter pub get` from the root of the repo
2. Run `pod install --repo-update` from `example/ios` directory
3. Run `flutter run` from the example directory or use XCode.
