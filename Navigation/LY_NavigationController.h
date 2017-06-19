//
//  LY_NavigationController.h
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LY_NavigationController : UINavigationController

@end

//禁用InteractivePopGesture手势
@interface UIViewController (LY_InteractivePopGesture)

//Defalut NO
@property (nonatomic, assign) BOOL ly_interactivePopDisabled;

@end
