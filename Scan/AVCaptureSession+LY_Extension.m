//
//  AVCaptureSession+LY_Extension.m
//  Scan
//
//  Created by CircleLi on 2017/3/22.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "AVCaptureSession+LY_Extension.h"

@implementation AVCaptureSession (LY_Extension)

- (void)ly_configurationSession:(void (^)())configurationSessionBlock{
    [self beginConfiguration];
    
    configurationSessionBlock();
    
    [self commitConfiguration];
}

@end
