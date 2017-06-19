//
//  AVCaptureDevice+LY_Extension.h
//  Scan
//
//  Created by CircleLi on 2017/3/23.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVCaptureDevice (LY_Extension)

- (void)ly_configurationDevice:(void(^)())configurationDeviceBlock;

@end
