Pod::Spec.new do |s|

  # Root specification
  s.name = 'PerformanceBezier'
  s.version = '0.1'
  s.license =  {:type => 'CC BY', :file => 'LICENSE' }
  s.summary = "A small library to dramatically speed up common operations on UIBezierPath, and also bring its functionality closer to NSBezierPath."
  s.homepage = 'https://github.com/adamwulf/PerformanceBezier'
  s.authors = {
    'Adam Wulf' => 'adam.wulf@gmail.com',
  }
  s.source = {
      :git => 'https://github.com/adamwulf/PerformanceBezier.git',
  }

  # File patterns
  s.source_files  = ['PerformanceBezier/PerformanceBezier.h', 'PerformanceBezier/UIBezierPath*.{h,m}']
  s.private_header_files = ['PerformanceBezier/UIBezierPathProperties.{h,m}', 'PerformanceBezier/UIBezierPath+FirstLast.{h,m}', 'PerformanceBezier/UIBezierPath+*Private.h']

  # Build settings
  s.framework = 'Foundation', 'UIKit'
  s.requires_arc = false
  s.dependency 'JRSwizzle', '~> 1.0'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC++ -lstdc++' }

  # Platform
  s.platform = :ios
  s.ios.deployment_target = "7.0"

end
