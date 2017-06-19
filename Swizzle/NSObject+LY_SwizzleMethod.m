//
//  NSObject+LY_SwizzleMethod.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "NSObject+LY_SwizzleMethod.h"
#import <objc/runtime.h>

@implementation NSObject (LY_SwizzleMethod)

+ (void)swizzleMehodWithClass:(Class)whichClass originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector{
    Class class = [whichClass class];//Class
    //Selector
    //    SEL originalSelector = @selector(setLeftBarButtonItem:animated:);
    //    SEL swizzledSelector = @selector(ly_setLeftBarButtonItem:animated:);
    //Method
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    //IMP
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    //DescriptionStr =  method's parameters +  method's return types.
    const char *originalDescriptionStr = method_getTypeEncoding(originalMethod);
    const char *swizzledDescriptionStr = method_getTypeEncoding(swizzledMethod);
    /*
     如果success == YES
     - (void)setLeftBarButtonItem:(nullable UIBarButtonItem *)item animated:(BOOL)animated{
     NSLog(@"Swizzle!!");
     [self ly_setLeftBarButtonItem:item animated:animated];
     }
     */
    BOOL success =  class_addMethod(class, originalSelector, swizzledIMP, swizzledDescriptionStr);
    if (success) {
        class_replaceMethod(class, swizzledSelector, originalIMP, originalDescriptionStr);
    }else{
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
