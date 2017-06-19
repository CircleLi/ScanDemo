//
//  UINavigationController+LY_Extension.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "UINavigationController+LY_Extension.h"

@implementation UINavigationController (LY_Extension)

- (void)ly_replaceTopViewController:(UIViewController *)newTopVC animated:(BOOL)animated{
    NSMutableArray *originalVCArray = [self.viewControllers mutableCopy];
    [originalVCArray removeObjectAtIndex:originalVCArray.count - 1];
    [originalVCArray addObject:newTopVC];
    [self setViewControllers:[originalVCArray copy] animated:animated];
}

@end
