//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<embeddedsdk/EmbeddedsdkPlugin.h>)
#import <embeddedsdk/EmbeddedsdkPlugin.h>
#else
@import embeddedsdk;
#endif

#if __has_include(<uni_links/UniLinksPlugin.h>)
#import <uni_links/UniLinksPlugin.h>
#else
@import uni_links;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [EmbeddedsdkPlugin registerWithRegistrar:[registry registrarForPlugin:@"EmbeddedsdkPlugin"]];
  [UniLinksPlugin registerWithRegistrar:[registry registrarForPlugin:@"UniLinksPlugin"]];
}

@end
