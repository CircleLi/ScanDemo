//
//  NSObject+LY_SwizzleMethod.h
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (LY_SwizzleMethod)

+ (void)swizzleMehodWithClass:(Class )whichClass
             originalSelector:(SEL)originalSelector
             swizzledSelector:(SEL)swizzledSelector;

@end
