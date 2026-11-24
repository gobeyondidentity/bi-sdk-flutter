//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<bi_sdk_flutter/EmbeddedSdkPlugin.h>)
#import <bi_sdk_flutter/EmbeddedSdkPlugin.h>
#else
@import bi_sdk_flutter;
#endif

#if __has_include(<flutter_web_auth_2/FlutterWebAuth2Plugin.h>)
#import <flutter_web_auth_2/FlutterWebAuth2Plugin.h>
#else
@import flutter_web_auth_2;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<url_launcher_ios/URLLauncherPlugin.h>)
#import <url_launcher_ios/URLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [EmbeddedSdkPlugin registerWithRegistrar:[registry registrarForPlugin:@"EmbeddedSdkPlugin"]];
  [FlutterWebAuth2Plugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterWebAuth2Plugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]];
}

@end
