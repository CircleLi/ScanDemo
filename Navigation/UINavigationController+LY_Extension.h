//
//  UINavigationController+LY_Extension.h
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (LY_Extension)

//替换NavigationController的 topViewController
- (void)ly_replaceTopViewController:(UIViewController *)newTopVC animated:(BOOL)animated;

@end
