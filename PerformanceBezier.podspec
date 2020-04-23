#
#  Be sure to run `pod spec lint PerformanceBezier.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "PerformanceBezier"
  spec.version      = "1.0.0"
  spec.summary      = "A small library to dramatically speed up common operations on UIBezierPath, and also bring its functionality closer to NSBezierPath"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
  This framework adds caching into every UIBezierPath so that common operations can be performed in constant time. It also adds some missing NSBezierPath methods to the UIBezierPath class.

  After linking this framework into your project, all Bezier paths will automatically be upgraded to use this new caching. No custom UIBezierPath allocation or initialization is required.
                   DESC

  spec.homepage     = "https://github.com/adamwulf/PerformanceBezier"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See https://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  # spec.license      = "MIT (example)"
  spec.license      = { :type => "CC-BY", :file => "LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.author             = { "Adam Wulf" => "adam.wulf@gmail.com" }
  # Or just: spec.author    = "Adam Wulf"
  # spec.authors            = { "Adam Wulf" => "adam.wulf@gmail.com" }
  # spec.social_media_url   = "https://twitter.com/Adam Wulf"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # spec.platform     = :ios
  spec.platform     = :ios, "8.0"

  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.source       = { :git => "https://github.com/adamwulf/PerformanceBezier.git", :tag => "#{spec.version}" }
  

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  spec.source_files  = "PerformanceBezier/**/*.{h,m}"
  spec.exclude_files = "PerformanceBezier/UIBezierPath+NSOSX.m","PerformanceBezier/UIBezierPath+Performance.m","PerformanceBezier/UIBezierPath+Trim.m","PerformanceBezier/UIBezierPathProperties.m"

  # spec.public_header_files = "Classes/**/*.h"

  # ――― No ARC ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.subspec 'no-arc' do |sp|
    sp.source_files = "PerformanceBezier/**/*.h","PerformanceBezier/UIBezierPath+NSOSX.{h,m}","PerformanceBezier/UIBezierPath+Performance.{h,m}","PerformanceBezier/UIBezierPathProperties.{h,m}","PerformanceBezier/UIBezierPath+Trim.{h,m}"
    sp.requires_arc = false
    sp.xcconfig = { "OTHER_LDFLAGS" => "-ObjC++ -lstdc++", "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++0x", "CLANG_CXX_LIBRARY" => "libc++", "GCC_C_LANGUAGE_STANDARD" => "gnu99" }
  end

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"

  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"

  # spec.library   = "libc++"
  # spec.libraries = "iconv", "xml2"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  spec.requires_arc = true

  spec.xcconfig = { "OTHER_LDFLAGS" => "-ObjC++ -lstdc++", "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++0x", "CLANG_CXX_LIBRARY" => "libc++" }
  # spec.dependency "JSONKit", "~> 1.4"

end
