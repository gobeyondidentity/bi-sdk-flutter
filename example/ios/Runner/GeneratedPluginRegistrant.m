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

#if __has_include(<flutter_web_auth/FlutterWebAuthPlugin.h>)
#import <flutter_web_auth/FlutterWebAuthPlugin.h>
#else
@import flutter_web_auth;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<uni_links/UniLinksPlugin.h>)
#import <uni_links/UniLinksPlugin.h>
#else
@import uni_links;
#endif

#if __has_include(<url_launcher_ios/FLTURLLauncherPlugin.h>)
#import <url_launcher_ios/FLTURLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [EmbeddedSdkPlugin registerWithRegistrar:[registry registrarForPlugin:@"EmbeddedSdkPlugin"]];
  [FlutterWebAuthPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterWebAuthPlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [UniLinksPlugin registerWithRegistrar:[registry registrarForPlugin:@"UniLinksPlugin"]];
  [FLTURLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTURLLauncherPlugin"]];
}

@end
