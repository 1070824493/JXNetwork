Pod::Spec.new do |s|
  s.name         = "JXNetwork"
  s.version      = "2.1.0"
  s.summary      = "JXNetwork"
  s.description  = "A description of JXNetwork."
  s.homepage     = "http://EXAMPLE/JXNetwork"
  s.license      = { :type => 'Commercial', :text => '© 2017 Juxin Technology Co., Ltd.' }
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "leowei" => "leowei" }
  # Or just: s.author    = "leowei1992"
  # s.authors            = { "leowei1992" => "leo_wei1992@163.com" }
  # s.social_media_url   = "http://twitter.com/leowei1992"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  s.platform     = :ios, "9.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => 'http://test.game.xiaoyouapp.cn:20080/iOS/JXNetwork.git', :tag => s.version }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #
  # s.public_header_files = "Sources/*.h"
  # s.frameworks = "CoreTelephony"
  # s.library   = "iconv"
  # s.libraries = "c++", "z"


  s.source_files = "Sources/**/*.{swift}"
  s.xcconfig = { 'SWIFT_INCLUDE_PATHS' =>
  '$(PODS_ROOT)/JXNetwork/Sources/CommonCrypto' }
  s.preserve_paths = 'Sources/CommonCrypto/module.modulemap'
  s.dependency            'MBProgressHUD'
  s.dependency            'CocoaLumberjack'
  s.dependency            'Alamofire'
  s.dependency            'SwiftyJSON'
  s.dependency            'EVReflection'
  s.dependency            'CocoaAsyncSocket'
  s.dependency            'JXEncrypt'
  s.dependency            'YYCache'


end
