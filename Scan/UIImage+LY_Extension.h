//
//  UIImage+LY_Extension.h
//  Scan
//
//  Created by CircleLi on 2017/4/5.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LY_Extension)
//根据比例缩放图片
- (UIImage *)scaledImageWithRatio:(CGFloat)ratio;

@end
