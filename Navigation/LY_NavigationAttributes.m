//
//  LY_NavigationAttributes.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "LY_NavigationAttributes.h"
#import <UIKit/UIKit.h>
NSString *const LY_BarButtonItem_TitleFont       = @"BarButtonItem_TitleFont";
NSString *const LY_BarButtonItem_TitleColor      = @"BarButtonItem_TitleColor";
NSString *const LY_NavigationItem_TitleFont      = @"NavigationItem_TitleFont";
NSString *const LY_NavigationItem_TitleColor     = @"NavigationItem_TitleColor";
NSString *const LY_NavigationBar_BackgroundColor = @"NavigationBar_BackgroundColor";

@implementation LY_NavigationAttributes

+ (NSDictionary *)shareNavigationAttributes{
    static NSDictionary *navigationAttirbutes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        navigationAttirbutes = @{
                                 LY_BarButtonItem_TitleFont       :  [UIFont systemFontOfSize:17.0f],
                                 LY_BarButtonItem_TitleColor      :  [UIColor whiteColor],
                                 LY_NavigationItem_TitleFont      :  [UIFont systemFontOfSize:17.0f],
                                 LY_NavigationItem_TitleColor     :  [UIColor whiteColor],
                                 LY_NavigationBar_BackgroundColor :  [UIColor colorWithRed:0/255.0f green:119/255.0f blue:196/255.0f alpha:1.0f],
                                 };
    });
    //
    return navigationAttirbutes;
}

@end
