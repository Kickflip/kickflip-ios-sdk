Pod::Spec.new do |s|
  s.name         = "Kickflip"
  s.version      = "1.1"
  s.summary      = "The Kickflip platform provides a complete video broadcasting solution for your iOS application."
  s.homepage     = "https://github.com/Kickflip/kickflip-ios-sdk"

  s.license      = 'Apache License, Version 2.0'

  s.author       = { "Chris Ballinger" => "chris@openwatch.net" }
  s.platform     = :ios, '7.0'
  s.source       = { :git => "https://github.com/Kickflip/kickflip-ios-sdk.git", :tag => s.version.to_s }

  s.source_files  = 'Kickflip', 'Kickflip/**/*.{h,m,mm,cpp}'
  s.resources = 'Kickflip/Resources/*'

  s.requires_arc = true

  s.libraries = 'c++'

  s.dependency 'AFNetworking'
  s.dependency 'AWSiOSSDK/S3'
  s.dependency 'AFOAuth2Client', :git => 'https://github.com/mlwelles/AFOAuth2Client
  s.dependency 'CocoaLumberjack'
  s.dependency 'SSKeychain'
  s.dependency 'FFmpegWrapper'
  s.dependency 'UIView+AutoLayout'
  s.dependency 'Mantle'
  s.dependency 'SDWebImage'
  s.dependency 'FormatterKit/TimeIntervalFormatter'
end
