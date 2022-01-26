#import "EmbeddedsdkPlugin.h"
#if __has_include(<embeddedsdk/embeddedsdk-Swift.h>)
#import <embeddedsdk/embeddedsdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "embeddedsdk-Swift.h"
#endif

@implementation EmbeddedsdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEmbeddedsdkPlugin registerWithRegistrar:registrar];
}
@end
