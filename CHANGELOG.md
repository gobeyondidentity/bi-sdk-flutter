# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2023-01-09
### Changed
- Rename instances of `Credential` to `Passkey`
- Update example app to authenticate with Beyond Identity by using Invocation Type `manual`
- Prefixed `Credential` properties to prevent name conflicts
- Nest tenantId, realmId, and identityId under appropriate objects in the `Credential`
- Update support links in the example app

### Fixed
- The SDK can now be imported into a default flutter project without compilation errors
- The example app now displays an error when attempting to authenticate without a credential
- Scheme without a path is now recognized as a valid URL when binding a credential

## [1.0.1] - 2022-11-18
### Changed
- Removed `url_launcher` as a dependency.

## [1.0.0] - 2022-09-21
### Changed
- Updated the Flutter SDK to support our newly released Secure Customer product. See the [documentation](https://developer.beyondidentity.com/docs/v1/sdks/flutter-sdk/overview) for more details.
