//
//  UIImage+LY_Extension.m
//  Scan
//
//  Created by CircleLi on 2017/4/5.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "UIImage+LY_Extension.h"

@implementation UIImage (LY_Extension)

- (UIImage *)scaledImageWithRatio:(CGFloat)ratio{
    CGSize size = self.size;
    CGFloat width = size.width;
    CGFloat height = size.height;
    CGFloat scaledWidth = width * ratio;
    CGFloat scaledHeight = height * ratio;
    UIGraphicsBeginImageContext(CGSizeMake(scaledWidth, scaledHeight));
    [self drawInRect:CGRectMake(0, 0, scaledWidth, scaledHeight)];
    UIImage* scaledImage= UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}



@end
