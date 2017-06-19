//
//  ScanViewController.h
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Scan_CaptureVideoManager.h"

typedef enum : NSUInteger {
    RecognizeAlgorithm_RainbowCode,//彩虹码
    RecognizeAlgorithm_BlackWhiteCode,//黑白码
    //RecognizeAlgorithm_AllCode,//识别以上所以类型条码
} RecognizeAlgorithm;

//彩虹码
extern NSString *const LY_RainbowBarcode_Key; // Value : NSString
extern NSString *const LY_RainbowColorInfo_Key; //Vlaue : NSString

//黑白码
extern NSString *const LY_BlackWhiteBarcode_Key; //Value : NSString
extern NSString *const LY_BlackWhiteBarcodeType_Key; //Value :NSNumber

@class ScanViewController;
@protocol ScanViewControllerDelegate <NSObject>

@optional

/**
 for NSDictionary *barcodeInfo , you'd better use :
 LY_RainbowBarcode_Key
 LY_RainbowColorInfo_Key
 LY_BlackWhiteBarcode_Key
 LY_BlackWhiteBarcodeType_Key
 */
- (void)scanVC_SuccessRecogize:(ScanViewController *)scanVC barcodeInfo:(NSDictionary *)barcodeInfo;

@end


@interface ScanViewController : UIViewController


@property (nonatomic, assign) RecognizeAlgorithm recognizeType;

/*
 虽然previewLayer展示的捕获画面很大，通常我们在扫码屏幕 上 还会限定一个小框 ， 这个小框就是recognizeLimitedArea，
 
 
 recognizeLimitedArea 是  以 ScanViewController.view 为superView 来 设定的 【因为内部已将 previewLayer.bounds == ScanViewController.view.bounds , 也就是 previewLayer 和ScanViewController.view 刚好重叠！】
 
 */
@property (nonatomic, assign) CGRect recognizeLimitedArea;


@property (nonatomic, weak) id <ScanViewControllerDelegate>delegate;


//扫码相机流管理工具(开始，停止，暂停,继续.......)
@property (nonatomic, strong, readonly) Scan_CaptureVideoManager *scanManager;



@end
