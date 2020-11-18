Pod::Spec.new do |s|
  s.name            = "PerformanceBezier"
  s.version         = "1.0.22"
  s.summary         = "A small library to dramatically speed up common operations on UIBezierPath, and also bring its functionality closer to NSBezierPath."
  s.author          = {
      'Adam Wulf' => 'adam.wulf@gmail.com',
  }
  s.homepage        = "https://github.com/adamwulf/PerformanceBezier"
  s.license         = {:type => 'CC BY', :file => 'LICENSE' }

  s.source          = { :git => "https://github.com/adamwulf/PerformanceBezier.git", :tag => s.version}
  s.source_files    = ['PerformanceBezier/PerformanceBezier.h', 'PerformanceBezier/UIBezierPath*.{h,m}', 'PerformanceBezier/JR*.{h,m}']
  s.private_header_files = ['PerformanceBezier/*_Private.h', 'PerformanceBezier/JRSwizzle.h']
  s.public_header_files = 'PerformanceBezier/*.h'


  s.platform = :ios
  s.ios.deployment_target   = "8.0"

  s.framework = 'Foundation', 'UIKit'

  s.requires_arc = false
  s.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC++ -lstdc++', "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++0x", "CLANG_CXX_LIBRARY" => "libc++"  }

end
