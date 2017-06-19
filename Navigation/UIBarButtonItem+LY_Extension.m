//
//  UIBarButtonItem+LY_Extension.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "UIBarButtonItem+LY_Extension.h"
#import "NSObject+LY_SwizzleMethod.h"
#import "LY_NavigationAttributes.h"
#import <objc/runtime.h>

@interface UINavigationItem (LY_Extension)

@end

/*
 不论leftItem,rightItem; 第一个item距离屏幕NavigationBar边缘 的 系统默认距离是16.0f;
 而, leftItem 之间  或者  rightItem 之间的距离  系统默认的间距是8.0f (且不论你如何设置, 系统不会让让你小于8.0f)
 
 由于16.0f ,8.0f的系统间距是我手动量出来的; 而且测试机型和系统也不多;
 可能由于机型或者系统 , 这2个值产生偏差,可以自行修改.
 
 */
#define SystemFirstItemSpace 16.0f
#define SystemItemAndItemSpace 8.0f

#define ButtonImage_Title_Space 6.0f

@implementation UINavigationItem (LY_Extension)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSObject swizzleMehodWithClass:self
                       originalSelector:@selector(setLeftBarButtonItem:animated:)
                       swizzledSelector:@selector(ly_setLeftBarButtonItem:animated:)];
        
        
        [NSObject swizzleMehodWithClass:self
                       originalSelector:@selector(setLeftBarButtonItems:animated:)
                       swizzledSelector:@selector(ly_setLeftBarButtonItems:animated:)];
        
        
        [NSObject swizzleMehodWithClass:self
                       originalSelector:@selector(setRightBarButtonItem:animated:)
                       swizzledSelector:@selector(ly_setRightBarButtonItem:animated:)];
        
        
        [NSObject swizzleMehodWithClass:self
                       originalSelector:@selector(setRightBarButtonItems:animated:)
                       swizzledSelector:@selector(ly_setRightBarButtonItems:animated:)];
    });
}

- (void)ly_setLeftBarButtonItem:(nullable UIBarButtonItem *)item animated:(BOOL)animated{
    if (item.leftSpace) {//设置了左边距
        UIBarButtonItem *fixedLeftSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedLeftSpaceItem.width = item.leftSpace.doubleValue - SystemFirstItemSpace;
        [self ly_setLeftBarButtonItems:@[fixedLeftSpaceItem,item] animated:animated];//IMP ->  setLeftBarButtonItems:animated:
    }else{//没有设置左边距,还是保持系统默认的左边距
        [self ly_setLeftBarButtonItems:nil animated:NO];//清空
        [self ly_setLeftBarButtonItem:item animated:animated];//再赋值
    }
}

- (void)ly_setLeftBarButtonItems:(nullable NSArray<UIBarButtonItem *> *)items animated:(BOOL)animated{
    NSMutableArray *fixedSpaceItems = [NSMutableArray arrayWithCapacity:2*items.count];
    [items enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (items[idx].leftSpace) {//设置了 space
            UIBarButtonItem *fixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            fixedSpaceItem.width = (idx == 0) ? (items[idx].leftSpace.doubleValue -SystemFirstItemSpace) : items[idx].leftSpace.doubleValue;
            [fixedSpaceItems addObject: fixedSpaceItem];//space
        }
        [fixedSpaceItems addObject:items[idx]];//item
    }];
    [self ly_setLeftBarButtonItems:fixedSpaceItems animated:animated];
}


- (void)ly_setRightBarButtonItem:(nullable UIBarButtonItem *)item animated:(BOOL)animated{
    if (item.rightSpace) {//设置了右边距
        UIBarButtonItem *fixedRightSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedRightSpaceItem.width = item.rightSpace.doubleValue - SystemFirstItemSpace;
        [self ly_setRightBarButtonItems:@[fixedRightSpaceItem,item] animated:animated];//IMP->setRightBarButtonItems: animated:
    }else{//没有设置右边距,还是保持系统默认的右边距
        [self ly_setRightBarButtonItems:nil animated:NO];//清空
        [self ly_setRightBarButtonItem:item animated:animated];//重新替换rightBarButtonItem
    }
    
}

- (void)ly_setRightBarButtonItems:(nullable NSArray<UIBarButtonItem *> *)items animated:(BOOL)animated{
    NSMutableArray *fixedSpaceItems = [NSMutableArray arrayWithCapacity:2*items.count];
    [items enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (items[idx].rightSpace) {//设置了 space
            UIBarButtonItem *fixedSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            fixedSpaceItem.width = (idx == 0) ? (items[idx].rightSpace.doubleValue -SystemFirstItemSpace) : items[idx].rightSpace.doubleValue;
            [fixedSpaceItems addObject: fixedSpaceItem];//space
        }
        [fixedSpaceItems addObject:items[idx]];//item
    }];
    [self ly_setRightBarButtonItems:fixedSpaceItems animated:animated];
}


@end


@implementation UIBarButtonItem (LY_Extension)

@dynamic leftSpace;
@dynamic rightSpace;

#pragma mark - AssociatedObject
- (void)setLeftSpace:(NSNumber *)leftSpace{
    objc_setAssociatedObject(self, @selector(leftSpace), leftSpace, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)leftSpace{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRightSpace:(NSNumber *)rightSpace{
    objc_setAssociatedObject(self, @selector(rightSpace), rightSpace, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)rightSpace{
    return objc_getAssociatedObject(self, _cmd);
}




+ (instancetype)barButtonItemWithImage:(NSString *)image
                                 title:(NSString *)title
                                target:(id)target
                                action:(SEL)selector{
    //Default Config , UI出图之后这里
    UIEdgeInsets imageEdgeInsets = UIEdgeInsetsZero;
    UIEdgeInsets titleEdgeInsets = UIEdgeInsetsMake(0.0f, ButtonImage_Title_Space, 0.0f, 0.0f);
    UIFont *titleFont = NavigationAttributes_Dictionary[LY_BarButtonItem_TitleFont];
    UIColor *titleColor = NavigationAttributes_Dictionary[LY_BarButtonItem_TitleColor];
    
    if (!image || !title) {//只要image，title其中任意 一个为nil
        imageEdgeInsets = UIEdgeInsetsZero;
        titleEdgeInsets = UIEdgeInsetsZero;
    }
    return [self barButtonItemWithNormalImage:image
                             highlightedImage:nil
                              imageEdgeInsets:imageEdgeInsets
                                  normalTitle:title
                             highlightedTitle:nil
                              titleEdgeInsets:titleEdgeInsets
                             normalTitleColor:titleColor
                       hightlightedTitleColor:nil
                                    titleFont:titleFont
                                barButtonsize:CGSizeZero
                                       target:target
                                       action:selector
                              backgroundColor:nil];
}


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
                             backgroundColor:(UIColor *)backgroundColor{
    
    return [[self alloc] initWithNormalImage:normalImage
                            highlightedImage:highlightedImage
                             imageEdgeInsets:imageEdgeInsets
                                 normalTitle:normalTitle
                            highlightedTitle:highlightedTitle
                             titleEdgeInsets:titleEdgeInsets
                            normalTitleColor:normalTitleColor
                      hightlightedTitleColor:hightlightedTitleColor
                                   titleFont:titleFont
                               barButtonsize:size
                                      target:target
                                      action:selector
                             backgroundColor:backgroundColor];
}


- (instancetype)initWithNormalImage:(NSString *)normalImage
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
                    backgroundColor:(UIColor *)backgroundColor{
    //对于自定义Btn 最好设置为Custom
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //设置 ContentImage
    [button setImage:normalImage ? [UIImage imageNamed:normalImage] : nil forState:UIControlStateNormal];//[UIImage imageNamed:nil] 会产生警告log
    
    [button setImage:highlightedImage ? [UIImage imageNamed:highlightedImage] : nil forState:UIControlStateHighlighted];
    
    //设置 ContentTitle
    [button setTitle:normalTitle forState:UIControlStateNormal];
    [button setTitle:highlightedTitle forState:UIControlStateHighlighted];
    [button setTitleColor:normalTitleColor forState:UIControlStateNormal];
    [button setTitleColor:hightlightedTitleColor forState:UIControlStateHighlighted];
    
    button.titleLabel.font = titleFont;
    
    /*
     UIButton Content 的内容 就是 setImage  和 setTitle ,
     1.只有setImage, Image居中显示
     2.只有setTitle, Title居中显示
     3.setImage和setTitle同是存在, 左Image 右Title
     
     如果你对Image和Title之间的间距不满意, 可以设置backBtn.titleEdgeInsets和backBtn.imageEdgeInsets
     */
    button.titleEdgeInsets = titleEdgeInsets;
    button.imageEdgeInsets = imageEdgeInsets;
    
    //设置 Btn大小
    CGRect frame = button.frame;
    frame.size = CGSizeEqualToSize(size, CGSizeZero) ? [button sizeThatFits:CGSizeZero] : size;
    frame.size = CGSizeMake(frame.size.width + ButtonImage_Title_Space, frame.size.height);
    button.frame = frame;
    
    
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    
    
    button.backgroundColor = backgroundColor ? backgroundColor : [UIColor clearColor];
    
    //self == [UIBarButtonItem alloc]
    UIBarButtonItem *customBarButtomItem = [self initWithCustomView:button];
    
    return customBarButtomItem;
}

@end
