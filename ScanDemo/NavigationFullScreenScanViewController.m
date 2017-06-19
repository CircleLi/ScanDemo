//
//  NavigationFullScreenScanViewController.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "NavigationFullScreenScanViewController.h"
#import "ScanViewController.h"

@interface NavigationFullScreenScanViewController ()
<ScanViewControllerDelegate>

@property (nonatomic, weak) ScanViewController *scanVC;

@property (nonatomic, strong) UIView *limitedArea;

@end

@implementation NavigationFullScreenScanViewController

#pragma mark - LazyLoading
- (ScanViewController *)scanVC{
    if (!_scanVC) {
        //
        ScanViewController *tmpVC = [[ScanViewController alloc] init];
        _scanVC = tmpVC;
        _scanVC.recognizeType = RecognizeAlgorithm_RainbowCode;
        //_scanVC.recognizeLimitedArea =
        _scanVC.delegate = self;
        //让scanVC的 生命周期与 self的生命周期 同步
        [self addChildViewController:_scanVC];
    }
    return _scanVC;
}


- (UIView *)limitedArea{
    if (!_limitedArea) {
        _limitedArea = [[UIView alloc] init];
        _limitedArea.backgroundColor = [UIColor clearColor];
        _limitedArea.layer.borderColor = [UIColor blueColor].CGColor;
        _limitedArea.layer.borderWidth = 2.0f;
    }
    return _limitedArea;
}

#pragma mark - LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.scanVC.view];
    
    [self.scanVC.view addSubview:self.limitedArea];
}


#pragma mark - Layout
- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    self.scanVC.view.frame = CGRectMake(0, 64.0f, SCREEN_WIDTH, SCREEN_HEIGHT - 64.0f);
    
    
    self.limitedArea.bounds = CGRectMake(0, 0, 200, 200);
    self.limitedArea.center = CGPointMake(CGRectGetWidth(self.scanVC.view.frame)/2, CGRectGetHeight(self.scanVC.view.frame)/2);
    self.scanVC.recognizeLimitedArea = self.limitedArea.frame;
    
}

#pragma mark - ScanViewControllerDelegate
- (void)scanVC_SuccessRecogize:(ScanViewController *)scanVC barcodeInfo:(NSDictionary *)barcodeInfo{
    NSLog(@"%@______%@",barcodeInfo[LY_RainbowBarcode_Key],barcodeInfo[LY_RainbowColorInfo_Key]);
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
