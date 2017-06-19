//
//  AVCaptureSession+LY_Extension.h
//  Scan
//
//  Created by CircleLi on 2017/3/22.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVCaptureSession (LY_Extension)


/**
 更加精细的水平调整AVCaptureSession配置参数，或者想给一个正在运行的AVCaptureSession做些配置修改，用 beginConfiguration 和 commitConfiguration 方法。beginConfiguration 和 commitConfiguration 方法确保设备作为一个群体在变化，将状态的清晰度或者不协调性 最小化。调用 beginConfiguration 之后，可以添加或者移除Outputs，改变 sessionPreset 属性，或者单独配置捕获输入或输出属性。在你调用 commitConfiguration 之前实际上是没有变化的，调用的时候它们(修改的AVCaptureSession配置参数)才被应用到一起。

 @param configurationSessionBlock :
 1. Add or Remove captureInput an capture device. (optional)
 2. Add or Remove captureOnput an capture device. (optional)
 3. Reset the preset.(optional)
 
  even if captureSession is running , you can invoke ly_configurationSession Method change sessionConfigruation
 
 */
- (void)ly_configurationSession:(void(^)())configurationSessionBlock;

@end
