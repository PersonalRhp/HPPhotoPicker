# PhotoPicker

[![CI Status](https://img.shields.io/travis/饶鸿平/PhotoPicker.svg?style=flat)](https://travis-ci.org/饶鸿平/PhotoPicker)
[![Version](https://img.shields.io/cocoapods/v/PhotoPicker.svg?style=flat)](https://cocoapods.org/pods/PhotoPicker)
[![License](https://img.shields.io/cocoapods/l/PhotoPicker.svg?style=flat)](https://cocoapods.org/pods/PhotoPicker)
[![Platform](https://img.shields.io/cocoapods/p/PhotoPicker.svg?style=flat)](https://cocoapods.org/pods/PhotoPicker)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

PhotoPicker is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'PhotoPicker'
```
## Config
![演示](https://github.com/PersonalRhp/HPPhotoPicker/blob/main/Example/PhotoPicker/ezgif.com-optimize.gif)
```
1. 图片多选和单选
2. 视频单选
3. 相机预览或占位
4. 媒体类型选择
5. 视频最大时长和最小时长
6. 图片裁剪
7. 支持记录选中图片
8. 支持记录选中数量
9. 照片时间排序
10.push、present跳转
11.自定义UI
```

## Structure
确定照片选择器需要实现的功能后，照片选择器可以拆分为选择、预览、编辑三大模块以及实现一些公共的扩展和管理类， 这里管理类主要有照片选择器配置、照片选择器管理、照片数据源管理、本地资源管理， 因为项目工期比较紧张，编辑这一块目前只实现了裁剪，用的第三方库实现，后面有时间会替换掉
![照片选择器结构](https://upload-images.jianshu.io/upload_images/5126938-ca02261d503641e2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

需要自己实现照片选择器的同学可以根据自己的项目进行修改,
也可以直接使用，目前未集成公有库，后期有同学需要，会考虑集成pods

简书 [照片选择器](https://www.jianshu.com/p/e424b11f3495)

## Author

饶鸿平, 1836619909@qq.com

## License

PhotoPicker is available under the MIT license. See the LICENSE file for more info.
