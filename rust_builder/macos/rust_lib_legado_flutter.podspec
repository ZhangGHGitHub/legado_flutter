#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rust_lib_legado_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rust_lib_legado_flutter'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.frameworks = 'SystemConfiguration', 'Security', 'CoreFoundation'
  s.swift_version = '5.0'

  rust_ldflags = '$(inherited) -force_load ${BUILT_PRODUCTS_DIR}/liblegado_engine.a -lc++ -framework SystemConfiguration -framework Security -framework CoreFoundation'

  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../../rust/legado_engine legado_engine',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ["${BUILT_PRODUCTS_DIR}/liblegado_engine.a"],
  }
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => rust_ldflags,
  }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -force_load ${PODS_CONFIGURATION_BUILD_DIR}/rust_lib_legado_flutter/liblegado_engine.a -lc++ -framework SystemConfiguration -framework Security -framework CoreFoundation',
  }
end
