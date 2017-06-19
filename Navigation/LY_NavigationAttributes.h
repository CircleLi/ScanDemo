//
//  LY_NavigationAttributes.h
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const LY_BarButtonItem_TitleFont;
extern NSString *const LY_BarButtonItem_TitleColor;
extern NSString *const LY_NavigationItem_TitleFont;
extern NSString *const LY_NavigationItem_TitleColor;
extern NSString *const LY_NavigationBar_BackgroundColor;

#define NavigationAttributes_Dictionary [LY_NavigationAttributes shareNavigationAttributes]


@interface LY_NavigationAttributes : NSObject

+ (NSDictionary *)shareNavigationAttributes;

@end
