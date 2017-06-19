//
//  Scan_CaptureVideoManager.h
//  Scan
//
//  Created by CircleLi on 2017/3/22.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/*
 关于使用ScanAlgorithm_System 和 ScanAlgorithm_Custom的优缺点
 
 ScanAlgorithm_System:
 优点：
 1.API非常简单易用
 2.rectOfInterest 设置简单 ， 不用自己去写复杂的代码完成 限定图像区域扫码问题
 3.Apple 转为iOS改良的算法，性能应该还不错
 缺点：
 1.如果支持的MetadataObjectTypes 中含有 二维码 ， 那么rectOfInterest的设置作用将 表现得不怎么明显 ，也就是说rectOfInterest不论如何设置，条码都要放在Central位置才能识别出来
 2.如果手机是 iPhone 4 ， 就算MetadataObjectTypes中 没有二维码 ，那么rectOfInterest的设置作用将 表现得不怎么明显 ，也就是说rectOfInterest不论如何设置，条码都要放在Central位置才能识别出来
 3.iOS7+ 支持扫码  ， iOS8+支持本地图片识别条码
 4.支持的 MetadataObjectTypes 类型只有那几种 ， 如果 要支持其他类型条码 ，ScanAlgorithm_System就不能采用
 
 ScanAlgorithm_Custom:
 优点：
 1.可以通过自己裁剪图片，比较准确地控制 rectOfInterest 
 2.能支持 Apple 以外的  条码类型
 3.扫码和条码图片识别  均支持iOS6+
 缺点:
 1. API使用复杂，而且需要自己处理每一帧图像 ， 涉及到一些图像操作(细到对每个像素，每个BGRA通道值的 操作)
 2. 可能ScanAlgorithm_Custom 不如 ScanAlgorithm_System 那么高效 (因为ScanAlgorithm_System是专门针对iOS来做的) 。
 
 
 到底是使用 ScanAlgorithm_System or ScanAlgorithm_Custom ，需要从以下几个因素权衡：
 1.最低支持的iOS系统版本
 2.支持的条码类型
 3.对于 rectOfInterest 是否要求非常严格
 4.如果仅仅支持 一维条形码的扫码， 个人非常 建议使用 使用 ScanAlgorithm_System ， 因为此时的扫描范围 Central+additional（Technical Note TN2325） ，而且这种情况下 rectOfInterest 设置效果非常明显
 5.你的具体开发周期
 
 
 */

typedef enum : NSUInteger {
    ScanAlgorithm_System,// Apple 原生扫描 .
    ScanAlgorithm_Custom,// ZXing ,Zbar .... 第三方扫描算法包.
} ScanAlgorithm;

@class Scan_CaptureVideoManager;
@protocol Scan_CaptureVideoManagerDelegate <NSObject>

@optional
//only for  ScanAlgorithm_Custom
- (void)scan_CaptureVideoManager:(Scan_CaptureVideoManager *)scanManager outputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

//only for  ScanAlgorithm_System , AVMetadataMachineReadableCodeObject 用于检测一维和二维 barcode
- (void)scan_CaptureMetadataManager:(Scan_CaptureVideoManager *)scanManager outputMetadataObjects:(NSArray <AVMetadataMachineReadableCodeObject *>*)metadataObjects;

/*
 更多关于AVMetadataMachineReadableCodeObject 的资料可以参考
 Technical Note TN2325 : 
 https://developer.apple.com/library/content/technotes/tn2325/_index.html
 */

@end


@interface Scan_CaptureVideoManager : NSObject

- (instancetype)initWithScanAlgorithmType:(ScanAlgorithm)scanAlgorithmType;

@property (nonatomic, assign, readonly) ScanAlgorithm scanAlgorithmType;

//人类视角 ， 专门为MetaDataOuput设计 ， 但是还没完全写好 
@property (nonatomic, assign) CGRect rectOfInterest;

@property (nonatomic, weak) id<Scan_CaptureVideoManagerDelegate> delegate;

//捕获画面展示
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;


//启动扫描,一般来说比较费时，为了用户体验，非常建议您在子线程中执行 此 Method (强烈建议:在子线程中执行，不然卡顿严重)
- (void)startScan;

/*
 停止扫描 , 有些许费时，在为了用户体验，非常建议您在子线程中执行 此 Method;
 stopScan必须要调用，如果不调用，导致相机流一直未关闭，从而引起其他界面时而卡顿，同时App在运行一段时间后自动崩溃。
 
 本人实测, stopScan 相比于 startScan  耗时少很多，完全在主线程中也并无大碍；
 如果你想在子线程中执行 stopScan ，由于你调用stopScan时可能会同时涉及到 某些对象的dealloc，请注意以下2点：
 1.僵尸内存带来的崩溃  EXC_BAD_ACCESS
 2.[nil stopScan] 造成调用失败 == 没有调用
 
 此Method 在主线程or 子线程中执行，请视具体情况而定！
 
 
 自己碰到的一种情况(极为少见)：
 由 扫码界面1 切换到 扫码界面2
 2个都是扫码界面，这种情况非常特殊； 如果是这种情况，扫码界面1 切换到 扫码界面2 时 ， 我们需要 手动 在主线程中调用一次 stopScan ；  理由：扫码界面1 切换到 扫码界面2 时 ， 如果我们依然在 子线程中执行扫码界面1 stopScan ， 扫码界面2的startScan也在子线程中执行，由于2个子线程不同， 会带来 stopScan和startScan的冲突，从而间接导致主线程卡顿！
 
 
 其他情况尽量在子线程中执行stopScan！
 
 
 */
- (void)stopScan;



//暂停扫描 (务必保证在主线程中执行)
- (void)suspendScan;
//恢复扫描 (务必保证在主线程中执行)
- (void)resumeScan;


#pragma mark - Device Characteristics
//设置扫描 聚焦模式
- (BOOL)setScan_FocusMode:(AVCaptureFocusMode)focusMode;

//设置聚焦兴趣点，设置聚焦兴趣点时，聚焦模式为AVCaptureFocusModeContinuousAutoFocus
- (BOOL)setScan_FocusPointOfInterest:(CGPoint )focusPointOfInterest;

/**
 设置扫描 手电筒模式
 
 对于一个有手电筒的设备，只有当该设备与一个正在运行的AVCaptureSession关联时，才能打开手电筒。
 */
- (BOOL)setScan_TorchMode:(AVCaptureTorchMode)torchMode;



@end
