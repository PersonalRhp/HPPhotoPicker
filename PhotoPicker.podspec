#
# Be sure to run `pod lib lint PhotoPicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PhotoPicker'
  s.version          = '1.0.6'
  s.summary          = '照片选择器'
  

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://www.jianshu.com/p/027518c2bbf1'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '饶鸿平' => '1836619909@qq.com' }
  s.source           = { :git => 'http://121.43.48.157/raohonping123456/PhotoPicker.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'PhotoPicker/Classes/**/*'
  s.swift_versions = '5.0'
  
  s.resource_bundles = {
    'PhotoPicker' => ['PhotoPicker/Assets/Resources/*.xcassets']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'SnapKit', '~> 5.0.1'
   s.dependency 'RSKImageCropper', '~> 3.0.2'
   s.dependency 'SwiftLint', '~> 0.43.0'
   s.dependency 'SwifterSwift/UIKit', '~> 5.2.0'
end
