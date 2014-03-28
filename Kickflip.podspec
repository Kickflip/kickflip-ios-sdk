Pod::Spec.new do |s|
  s.name         = "Kickflip"
  s.version      = "0.9"
  s.summary      = "The Kickflip platform provides a complete video broadcasting solution for your iOS application."
  s.homepage     = "https://github.com/Kickflip/kickflip-ios-sdk"

  s.license      = 'Apache License, Version 2.0'

  s.author       = { "Chris Ballinger" => "chris@openwatch.net" }
  s.platform     = :ios, '7.0'
  s.source       = { :git => "https://github.com/Kickflip/kickflip-ios-sdk.git", :tag => "0.9" }

  s.source_files  = 'Kickflip', 'Kickflip/**/*.{h,m}'

  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 1.3'
  s.dependency 'AFOAuth2Client', '~> 0.1'
  s.dependency 'CocoaLumberjack', '~> 1.0'
  s.dependency 'SSKeychain', '~> 1.2'
  s.dependency 'OWS3Client', '~> 1.0'
  s.dependency 'FFmpegWrapper', '~> 1.0'
end
