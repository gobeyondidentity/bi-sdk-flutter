# THIS FILE IS GENERATED. DO NOT EDIT.
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint embeddedsdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name              = 'embeddedsdk'
  s.version           = '0.3.0'
  s.summary           = 'Passwordless identities for workforces and customers'
  s.homepage          = 'https://beyondidentity.com'
  s.license           = { :file => '../LICENSE' }
  s.documentation_url = 'https://developer.beyondidentity.com'
  s.author            = 'Beyond Identity'
  s.source            = { :git => 'https://github.com/gobeyondidentity/bi-sdk-flutter.git', :tag => s.version.to_s }
  s.source_files      = 'Classes/**/*'

  s.platforms         = { :ios => "12.0" }
  s.swift_version     = '5.5'

  s.dependency 'Flutter'
  s.dependency 'BeyondIdentityEmbedded', '0.7.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
