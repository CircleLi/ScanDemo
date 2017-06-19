//
//  UINavigationBar+LY_Extension.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "UINavigationBar+LY_Extension.h"
#import <objc/runtime.h>
@implementation UINavigationBar (LY_Extension)

@dynamic ly_hideBottomLine;
@dynamic ly_alpha;

#pragma mark - AssociatedObject
- (void)setLy_hideBottomLine:(BOOL)ly_hideBottomLine{
    
    self.subviews[0].subviews[0].hidden = ly_hideBottomLine;
    
    NSNumber *boolNumber = [NSNumber numberWithBool:ly_hideBottomLine];
    objc_setAssociatedObject(self, @selector(ly_hideBottomLine), boolNumber, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)ly_hideBottomLine{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setLy_alpha:(CGFloat)ly_alpha{
    
    self.subviews[0].alpha = ly_alpha;
    
    NSNumber *floatNumber = [NSNumber numberWithFloat:ly_alpha];
    objc_setAssociatedObject(self, @selector(ly_alpha), floatNumber, OBJC_ASSOCIATION_ASSIGN);
}

- (CGFloat)ly_alpha{
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}



@end
