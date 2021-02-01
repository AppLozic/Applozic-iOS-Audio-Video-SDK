#
# Be sure to run `pod lib lint ApplozicAudioVideo.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'ApplozicAudioVideo'
    s.version          = '0.1.0'
    s.summary          = 'Applozic Audio Video iOS SDK'
    s.description      = <<-DESC
    The Applozic Audio Video SDK helps you to add audio, video calls with messaging into your iOS app.
    DESC

    s.homepage         = 'https://github.com/AppLozic/ApplozicAudioVideo'
    s.license = { :type => "BSD 3-Clause", :file => "LICENSE" }
    s.source           = { :git => 'https://github.com/AppLozic/ApplozicAudioVideo.git', :tag => s.version.to_s }
    s.social_media_url = 'http://twitter.com/AppLozic'
    s.authors = { 'Applozic Inc.' => 'support@applozic.com' }
    s.swift_version = '5.0'
    s.ios.deployment_target = '11.0'
    s.source_files = 'ApplozicAudioVideo/**/*.{h,m,swift}'
    s.requires_arc = true
    s.resources = 'ApplozicAudioVideo/**/*.{lproj,storyboard,xib,xcassets,json}'
    s.frameworks = 'CallKit'
    s.dependency 'Applozic', '~> 7.14.0'
    s.dependency 'TwilioVideo', '~> 4.2'
    s.ios.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
