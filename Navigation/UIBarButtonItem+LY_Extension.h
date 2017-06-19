//
//  UIBarButtonItem+LY_Extension.h
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (LY_Extension)

//Just for leftItem.If you not assign or assign nil , default = SystemLeftSpace;
@property (nonatomic, strong) NSNumber *leftSpace;

//Just for rightItem.If you not assign or assign nil , default = SystemRightSpace
@property (nonatomic, strong) NSNumber *rightSpace;


+ (instancetype)barButtonItemWithImage:(NSString *)image
                                 title:(NSString *)title
                                target:(id)target
                                action:(SEL)selector;

+ (instancetype)barButtonItemWithNormalImage:(NSString *)normalImage
                            highlightedImage:(NSString *)highlightedImage
                             imageEdgeInsets:(UIEdgeInsets)imageEdgeInsets
                                 normalTitle:(NSString *)normalTitle
                            highlightedTitle:(NSString *)highlightedTitle
                             titleEdgeInsets:(UIEdgeInsets)titleEdgeInsets
                            normalTitleColor:(UIColor *)normalTitleColor
                      hightlightedTitleColor:(UIColor *)hightlightedTitleColor
                                   titleFont:(UIFont *)titleFont
                               barButtonsize:(CGSize)size
                                      target:(id)target
                                      action:(SEL)selector
                             backgroundColor:(UIColor *)backgroundColor;


@end
