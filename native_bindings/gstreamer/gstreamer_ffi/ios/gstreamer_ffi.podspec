#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gstreamer_ffi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'gstreamer_ffi'
  s.version          = '0.0.1'
  s.summary          = 'GStreamer bindings'
  s.description      = <<-DESC
GStreamer bindings
                       DESC
  s.homepage         = 'https://github.com/juho05/crossonic'
  s.license          = { :file => '../../../../../LICENSE' }
  s.author           = { 'Julian Hofmann' => 'git@julianh.de' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64',   'HEADER_SEARCH_PATHS' => '"${HOME}/Library/Developer/GStreamer/iPhone.sdk/GStreamer.framework/Headers"',   'LD_RUNPATH_SEARCH_PATHS' => ['"${HOME}/Library/Developer/GStreamer/iPhone.sdk/"','"${HOME}/Library/Developer/GStreamer/iPhone.sdk/GStreamer.framework/Libraries"'], 'OTHER_LDFLAGS' => '" -L${HOME}/Library/Developer/GStreamer/iPhone.sdk/GStreamer.framework/Libraries -F${HOME}/Library/Developer/GStreamer/iPhone.sdk/ -framework GStreamer "', 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) IOS=1' }
  s.libraries= 'iconv','resolv','c++'
  s.framework= 'AudioToolbox', 'AVFoundation'
  s.swift_version = '5.0'
end
