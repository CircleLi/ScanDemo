//
//  AVCaptureDevice+LY_Extension.m
//  Scan
//
//  Created by CircleLi on 2017/3/23.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "AVCaptureDevice+LY_Extension.h"

@implementation AVCaptureDevice (LY_Extension)

- (void)ly_configurationDevice:(void (^)())configurationDeviceBlock{
    if ([self lockForConfiguration:nil]) {//获得设备锁
        configurationDeviceBlock();//设置设备
        [self unlockForConfiguration];//释放锁
    }else{
        [NSException raise:@"设置设备属性时,无法获取设备锁" format:@"O(∩_∩)O哈哈~"];
    }
}

@end
