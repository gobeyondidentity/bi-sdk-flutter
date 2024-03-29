#import "EmbeddedSdkPlugin.h"
#if __has_include(<bi_sdk_flutter/bi_sdk_flutter-Swift.h>)
#import <bi_sdk_flutter/bi_sdk_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "bi_sdk_flutter-Swift.h"
#endif

@implementation EmbeddedSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEmbeddedSdkPlugin registerWithRegistrar:registrar];
}
@end
