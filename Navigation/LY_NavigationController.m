//
//  LY_NavigationController.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "LY_NavigationController.h"
#import "UIBarButtonItem+LY_Extension.h"
#import "LY_NavigationAttributes.h"
#import "UINavigationBar+LY_Extension.h"
#import <objc/runtime.h>

#define BackButtonLeftSpace 8.5f

@interface LY_NavigationController ()

@end

@implementation LY_NavigationController

+ (void)initialize{
    UINavigationBar *navBar_appearance = [UINavigationBar appearance];
    
    UIBarButtonItem *barButtonItem_appearance;
    if ([[UIDevice currentDevice].systemVersion compare:@"9.0" options:NSNumericSearch] == NSOrderedAscending) {
#if (__IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0)
        barButtonItem_appearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
#endif
    }else{
        barButtonItem_appearance = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]];
    }
    //navBar背景颜色
    navBar_appearance.barTintColor = NavigationAttributes_Dictionary[LY_NavigationBar_BackgroundColor];
    //navBar字体相关属性
    navBar_appearance.titleTextAttributes = @{
                                              NSForegroundColorAttributeName:NavigationAttributes_Dictionary[LY_NavigationItem_TitleColor],
                                              NSFontAttributeName:NavigationAttributes_Dictionary[LY_NavigationItem_TitleFont],
                                              };
    
    [barButtonItem_appearance setTitleTextAttributes:@{
                                                       NSForegroundColorAttributeName:NavigationAttributes_Dictionary[LY_BarButtonItem_TitleColor],
                                                       NSFontAttributeName:NavigationAttributes_Dictionary[LY_BarButtonItem_TitleFont],
                                                       }
                                            forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    
    /*
     UINavigationControllerDelegate 方法调用
     */
    self.delegate = (id<UINavigationControllerDelegate>)self;
    
    self.navigationBar.ly_hideBottomLine = YES;
    //self.navigationBar.ly_alpha = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    
    viewController.automaticallyAdjustsScrollViewInsets = NO;
    if (self.viewControllers.count > 0) {
        //vc1->vc2 之前, 设置vc2.hidesBottomBarWhenPushed
        viewController.hidesBottomBarWhenPushed = YES;
    }
    
    
    if (self.viewControllers.count >0) {
        /*
         除了NavigationController的第一级不带有返回按钮之外，后面每一层级自动加上一个返回按钮.
         如果你不想要这个backBarButtonItem，你可以在具体的VC中重设leftBarButtonItem的值即可。
         */
        UIBarButtonItem *backBarButtonItem = [UIBarButtonItem barButtonItemWithImage:@"NavigationBackArrow" title:@"返回" target:self action:@selector(onBack)];
        backBarButtonItem.leftSpace = @(BackButtonLeftSpace);
        
        viewController.navigationItem.leftBarButtonItem = backBarButtonItem;
    }
    
    //触发实际的push 效果
    
    [super pushViewController:viewController animated:animated];
    
}


- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated{
    
    for (UIViewController *viewController in viewControllers) {
        viewController.automaticallyAdjustsScrollViewInsets = NO;
        if ([viewControllers[0] isEqual:viewController]) {//为首页，不做任何改变
            continue;
        }
        if (!viewController.navigationItem.leftBarButtonItem) {//没有leftBarButtonItem
            UIBarButtonItem *backBarButtonItem = [UIBarButtonItem barButtonItemWithImage:@"NavigationBackArrow" title:@"返回" target:self action:@selector(onBack)];
            backBarButtonItem.leftSpace = @(BackButtonLeftSpace);
            
            viewController.navigationItem.leftBarButtonItem = backBarButtonItem;
        }
    }
    
    
    [super setViewControllers:viewControllers animated:animated];
}

//当前navigationController pop 一层 view曾
- (UIViewController *)popViewControllerAnimated:(BOOL)animated{
    
    return [super popViewControllerAnimated:animated];
}


#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    
    
}


#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    
    if (self.viewControllers.count <= 1) {
        return NO;
    }
    
    if (self.topViewController.ly_interactivePopDisabled) {
        return NO;
    }
    
    return YES;
}

#pragma mark - onMethod
- (void)onBack{//返回
    [self popViewControllerAnimated:YES];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end


@implementation UIViewController (LY_InteractivePopGesture)

@dynamic ly_interactivePopDisabled;

- (void)setLy_interactivePopDisabled:(BOOL)ly_interactivePopDisabled{
    objc_setAssociatedObject(self, @selector(ly_interactivePopDisabled), @(ly_interactivePopDisabled), OBJC_ASSOCIATION_ASSIGN);
}


- (BOOL)ly_interactivePopDisabled{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}


@end

