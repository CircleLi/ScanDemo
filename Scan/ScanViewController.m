//
//  ScanViewController.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "ScanViewController.h"
#import "Scan_CaptureVideoManager.h"
#import "Scan_PixelBufferUtils.h"
#import "Scan_CaptureVideoMacros.h"

//彩虹码
NSString *const LY_RainbowBarcode_Key = @"RainbowBarcode";
NSString *const LY_RainbowColorInfo_Key = @"RainbowColorInfo";

NSString *const LY_BlackWhiteBarcode_Key = @"BlackWhiteBarcode";
NSString *const LY_BlackWhiteBarcodeType_Key = @"BlackWhiteBarcodeType";


typedef struct ClipParametersStruct{
    //人类视角
    CGFloat clip_x;
    CGFloat clip_y;
    CGFloat clip_w;
    CGFloat clip_h;
    //camera视角
    size_t  clip_camera_w;
    size_t  clip_camera_h;
}ClipParameters;

/**
 彩虹码 扫码专用函数
 
 @param data_rgb <#data_rgb description#>
 @param width <#width description#>
 @param height <#height description#>
 @param rotate_flag <#rotate_flag description#>
 @param debugInfo <#debugInfo description#>
 @param code <#code description#>
 @param colorInfor <#colorInfor description#>
 @return <#return value description#>
 */
extern int wcc_rainbow_scan(unsigned char *data_rgb, int width, int height, int rotate_flag,unsigned char *debugInfo,unsigned char *code,unsigned char *colorInfor);


/**
 扫描混合码(普通EN13条码、QRCode和快递码等)
 */
typedef struct HZRECT
{
    int x;
    int y;
    int width;
    int height;
}HZRECT;

//此函数需要手动链接libiconv.tbd    libstdc++.tbd 2个库，否则无法编译成功
extern int hz_ProcessFrame(unsigned char *m_FrameData,int width, int height, HZRECT *m_ActiveRect,char *m_result,int *m_bartype,int rotate_flag, int enable_blur);


@interface ScanViewController ()<Scan_CaptureVideoManagerDelegate>


/*
 扫码控制串行队列
 1.一定要保证camera的开启和关闭，在子线程中进行，否则可能会发生概率性卡顿，后果非常严重
 2.相机的开启 和 关闭 还必须保证在 同一子线程中进行，否则会引发多线安全问题 ， 造成扫码界面暂停的现象！
 */
@property (nonatomic, strong) dispatch_queue_t scanControlserialQueue;


//判断是否第一次调用viewWillAppear:
@property (nonatomic, assign) BOOL isVirgin;

//扫码界面如果置于NavigationController中，如果在interactivePopGesture有效；可能有用户在扫码界面反复地push ，pop， 这是可能带来相机的频繁地start 和 stop， 从而导致非常卡顿； 此 isStart 就是起一个堆栈的作用，在短时间内过滤掉 重复的 start 和 stop。
@property (atomic, assign) BOOL isStart;

@end

@implementation ScanViewController

@synthesize  scanManager = _scanManager;

#pragma mark - LazyLoading
- (Scan_CaptureVideoManager *)scanManager{
    if (!_scanManager) {
        _scanManager = [[Scan_CaptureVideoManager alloc] initWithScanAlgorithmType:ScanAlgorithm_Custom];
        _scanManager.delegate = self;
        [_scanManager setScan_FocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [_scanManager setScan_FocusPointOfInterest:CGPointMake(0.5, 0.5)];
    }
    return _scanManager;
}



- (dispatch_queue_t)scanControlserialQueue{
    if (!_scanControlserialQueue) {
        _scanControlserialQueue = dispatch_queue_create("com.CircleLi_Manager_Camera_StartOrStop", DISPATCH_QUEUE_SERIAL);
    }
    return _scanControlserialQueue;
}


#pragma mark - LifeCycle
- (instancetype)init{
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        _isVirgin = YES;
    }
    return self;
}

/********
 利用ViewController的生命周期：
 控制 capatureSession的 启动 、停止 、数据流连接 、数据流断开
 ==> scanManager    的 start、stop、resumeScan、suspendScan
 
 避免用户变态操作： 反复不停地PopGesture 带来的概率性卡顿问题
 
 ***********/

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor orangeColor];
    [self.view.layer addSublayer:self.scanManager.previewLayer];
    
    
    @weakify(self)
    dispatch_async(self.scanControlserialQueue, ^{
        @strongify(self)
        [self.scanManager startScan];
    });
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!_isVirgin) {
        self.isStart = YES;
        @weakify(self)
        dispatch_async(self.scanControlserialQueue, ^{
            @strongify(self)
            if (self.isStart) {
                [self.scanManager startScan];
            }
        });
        
    }
    _isVirgin = NO;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.isStart = NO;
    @weakify(self)
    dispatch_async(self.scanControlserialQueue, ^{
        @strongify(self)
        if (!self.isStart) {
            [self.scanManager stopScan];
        }
        
    });
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}



- (void)dealloc{
    
}

#pragma mark - Layout
- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    self.scanManager.previewLayer.frame = self.view.bounds;
    
    
}


#pragma mark - Scan_CaptureVideoManagerDelegate
- (void)scan_CaptureVideoManager:(Scan_CaptureVideoManager *)scanManager outputPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    //    size_t fw = [Scan_PixelBufferUtils getHeight:pixelBuffer];
    //    size_t fh = [Scan_PixelBufferUtils getWidth:pixelBuffer];
    
    //裁剪参数计算
    ClipParameters clipParameters = [self clipCVPixelBuffer:pixelBuffer scanAreaFrame:self.recognizeLimitedArea superviewBoundsOfscanArea:self.view.bounds];
    //人类视角
    CGFloat clip_x = clipParameters.clip_x;
    CGFloat clip_y = clipParameters.clip_y;
    CGFloat clip_w = clipParameters.clip_w;
    CGFloat clip_h = clipParameters.clip_h;
    //camera视角
    size_t clip_camera_w = clipParameters.clip_camera_w;
    size_t clip_camera_h = clipParameters.clip_camera_h;
    
    //图片裁剪
    uint8_t *clipImageBaseAddress = [Scan_PixelBufferUtils clipPixelBuffer:pixelBuffer frame:CGRectMake(clip_x, clip_y, clip_w, clip_h)];
    
    BOOL isRecognizeSuccess = NO;
    
    if (self.recognizeType == RecognizeAlgorithm_RainbowCode && !isRecognizeSuccess) {
        //1.扫描彩虹码
        isRecognizeSuccess = [self rainbowCodeAlgorithm:clipParameters clipImageBaseAddress:clipImageBaseAddress orignalPixelBuffer:pixelBuffer];
    }else if (self.recognizeType == RecognizeAlgorithm_BlackWhiteCode && !isRecognizeSuccess){
        //2. 扫描混合码(普通EN13条码、QRCode和快递码等)
        [self mixCodeAlgorithm:clipParameters clipImageBaseAddress:clipImageBaseAddress orignalPixelBuffer:pixelBuffer];
    }
    
    free(clipImageBaseAddress);
}


#pragma mark - HandlePixelBuffer
- (ClipParameters)clipCVPixelBuffer:(CVPixelBufferRef)pixelBuffer scanAreaFrame:(CGRect)frame superviewBoundsOfscanArea:(CGRect)superviewBounds{
    size_t fw = [Scan_PixelBufferUtils getHeight:pixelBuffer];
    size_t fh = [Scan_PixelBufferUtils getWidth:pixelBuffer];
    
    CGFloat visualWidth = CGRectGetWidth(self.view.bounds);
    CGFloat visualHeight = CGRectGetHeight(self.view.bounds);
    //
    //    if ( (fw/fh) < (visualWidth/visualHeight) ) {
    //        fw = fw;
    //        fh = visualHeight * (fw/visualWidth);
    //    }else if ( (fw/fh) > (visualWidth/visualHeight) ){
    //        fw = visualWidth * (fh/visualHeight);
    //        fh = fh;
    //    }
    
    //裁剪比例计算
    CGRect rectOfScanArea = self.recognizeLimitedArea;
    CGRect rectOfSelfView = self.view.bounds;
    if (( (CGFloat)fw/(CGFloat)fh ) < (visualWidth/visualHeight)) {
        CGFloat actualWidth = CGRectGetWidth(self.view.bounds);
        CGFloat actualHeight = fh/(fw/CGRectGetWidth(self.view.bounds)) ;
        
        rectOfSelfView = CGRectMake(0, 0, actualWidth, actualHeight);
        
        rectOfScanArea.origin.y += (actualHeight - CGRectGetHeight(self.view.bounds))/2.0;//这里 除以2.0 ,是因为previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill 的特性
    }else if ( ((CGFloat)fw/(CGFloat)fh ) > (visualWidth/visualHeight) ){
        CGFloat actualWidth = fw/(fh/CGRectGetHeight(self.view.bounds));
        CGFloat actualHeight = CGRectGetHeight(self.view.bounds) ;
        
        rectOfSelfView = CGRectMake(0, 0, actualWidth, actualHeight);
        
        rectOfScanArea.origin.x += (actualWidth - CGRectGetWidth(self.view.bounds))/2.0;//这里 除以2.0 ,是因为previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill 的特性
    }
    
    
    CGFloat clip_wRatio = CGRectGetWidth(rectOfScanArea)/CGRectGetWidth(rectOfSelfView);
    CGFloat clip_hRatio = CGRectGetHeight(rectOfScanArea)/CGRectGetHeight(rectOfSelfView);
    CGFloat clip_xRatio = CGRectGetMinX(rectOfScanArea)/CGRectGetWidth(rectOfSelfView);
    CGFloat clip_yRatio = CGRectGetMinY(rectOfScanArea)/CGRectGetHeight(rectOfSelfView);
    
    //根据_scanAreaView的边框，算裁剪边框 , 人类视角
    CGFloat clip_w = clip_wRatio*fw;
    CGFloat clip_h = clip_hRatio*fh;
    CGFloat clip_x = clip_xRatio*fw;
    CGFloat clip_y = clip_yRatio*fh;
    
    //camera视角
    size_t clip_camera_w = (size_t)clip_h;
    size_t clip_camera_h = (size_t)clip_w;
    
    ClipParameters clipParameters;
    clipParameters.clip_x = clip_x;
    clipParameters.clip_y = clip_y;
    clipParameters.clip_w = clip_w;
    clipParameters.clip_h = clip_h;
    clipParameters.clip_camera_w = clip_camera_w;
    clipParameters.clip_camera_h = clip_camera_h;
    
    return clipParameters;
}

- (BOOL)rainbowCodeAlgorithm:(ClipParameters)clipParameters clipImageBaseAddress:(uint8_t *)clipImageBaseAddress orignalPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    BOOL RecognizeSuccess = NO;
    
    //去Alpha Chnnel
    uint8_t *clipImageWithoutAlphaBaseAddress = [Scan_PixelBufferUtils removeAlphaChannelWithPixelBufferAddress:clipImageBaseAddress totalPixelCounts:((size_t)clipParameters.clip_camera_w * (size_t)clipParameters.clip_camera_h)];
    
    
    int      rainbowScanResult = 0;
    int      rotateFlag = 1;//目前仅仅为竖屏
    
    uint8_t *rainbowDebugInfo = (uint8_t *)malloc(sizeof(uint8_t) * 1025);
    uint8_t *rainbowCode = (uint8_t *)malloc(sizeof(uint8_t) * 100);
    uint8_t *rainbowColorInfo = (uint8_t *)malloc(sizeof(uint8_t) * 100);
#if !TARGET_IPHONE_SIMULATOR
    //rainbowScanResult = wcc_rainbow_scan(clipImageWithoutAlphaBaseAddress, clipParameters.clip_camera_w, clipParameters.clip_camera_h, rotateFlag, rainbowDebugInfo, rainbowCode, rainbowColorInfo);
    
    if (rainbowScanResult & 0xFC) {
        /*
         rainbowScanResult & 0xFC
         等价于
         rainbowScanResult!=0 &&
         rainbowScanResult!=1 &&
         rainbowScanResult!=2 &&
         rainbowScanResult!=3
         */
        for (int i=3; i>-1; i--) {
            if (i != rotateFlag) {
                //rainbowScanResult = wcc_rainbow_scan(clipImageWithoutAlphaBaseAddress, clipParameters.clip_camera_w, clipParameters.clip_camera_h, i, rainbowDebugInfo, rainbowCode, rainbowColorInfo);
                if ((rainbowScanResult & 0xFC) == 0)
                /*
                 (rainbowScanResult & 0xFC) == 0
                 等价于
                 rainbowScanResult == 0 ||
                 rainbowScanResult == 1 ||
                 rainbowScanResult == 2 ||
                 rainbowScanResult == 3
                 */
                    break;
                
            }
        }
    }
#endif
    NSString *strRainbowColorInfo = [NSString stringWithCString:(const char *)rainbowColorInfo encoding:NSUTF8StringEncoding];
    NSString *strRainbowCode = [NSString stringWithCString:(const char *)rainbowCode encoding:NSUTF8StringEncoding];
    if ((rainbowScanResult & 0xFC) == 0 &&
        ![strRainbowColorInfo isEqualToString:@"0"] && //识别为了普通黑白条码
        ![strRainbowColorInfo isEqualToString:@"1"]) { //去掉闪光灯情况
#if DEBUG
        UIImage *orignalImage = [Scan_PixelBufferUtils pixelBuffer_Convert_image32BGRA:CVPixelBufferGetBaseAddress(pixelBuffer) width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer)];
        UIImage *clipImage = [Scan_PixelBufferUtils pixelBuffer_Convert_image32BGRA:clipImageBaseAddress width:clipParameters.clip_camera_w height:clipParameters.clip_camera_h];
        NSLog(@"%d_%@_%@",rainbowScanResult,strRainbowCode,strRainbowColorInfo);
        NSData *clipImageData = UIImageJPEGRepresentation(clipImage, 1);
        NSData *originalImageData = UIImageJPEGRepresentation(orignalImage, 1);
        NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *savePath1 = [documentPath stringByAppendingPathComponent:@"clipImageData.jpg"];
        NSString *savePath2 = [documentPath stringByAppendingPathComponent:@"orignalImageData.jpg"];
        NSLog(@"%@\n%@",savePath1,savePath2);
        
        if ([clipImageData writeToFile:savePath1 atomically:YES] && [originalImageData writeToFile:savePath2 atomically:YES]) {
            NSLog(@"写入成功！");
        }
#endif
        //扫描识别成功，断开数据流连接 (数据流的断开 务必 在主线程中操作)
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        @weakify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self)
            [self.scanManager suspendScan];
            dispatch_semaphore_signal(semaphore);
        });
        
        if (_delegate && [_delegate respondsToSelector:@selector(scanVC_SuccessRecogize:barcodeInfo:)]) {
            [self playBeepSound];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate scanVC_SuccessRecogize:self barcodeInfo:@{LY_RainbowBarcode_Key:strRainbowCode,
                                                                     LY_RainbowColorInfo_Key:strRainbowColorInfo}];
            });
        }
    }
    
    free(rainbowDebugInfo);
    free(rainbowCode);
    free(rainbowColorInfo);
    
    
    free(clipImageWithoutAlphaBaseAddress);
    
    return RecognizeSuccess;
}


- (BOOL)mixCodeAlgorithm:(ClipParameters)clipParameters clipImageBaseAddress:(uint8_t *)clipImageBaseAddress orignalPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    BOOL RecognizeSuccess = NO;
    
    //单通道的图片的 基地址，每个像素仅1个通道
    uint8_t *singleChannelBaseAddress = [Scan_PixelBufferUtils getSingleChannel_B_G_R_X_WithPixelBufferBaseAddress:clipImageBaseAddress width:clipParameters.clip_camera_w height:clipParameters.clip_camera_h];
    
    
    int iRotate_flag = 1;//目前只支持竖屏
    int result = 0;
    uint8_t m_result[5000];
    int enable_blur = 0;//模糊识别关闭为0，一般来说内存是足够的;不够时可考虑开启，开启为1
    int m_barType = 0;
    HZRECT hzRect;
    hzRect.x = 0;
    hzRect.y = 0;
    hzRect.width = (int)clipParameters.clip_camera_w;
    hzRect.height = (int)clipParameters.clip_camera_h;
#if !TARGET_IPHONE_SIMULATOR
    
    //result = hz_ProcessFrame(singleChannelBaseAddress, hzRect.width, hzRect.height, &hzRect, (char *)m_result, &m_barType, iRotate_flag, enable_blur);
#endif
    if (result == 2) {
#if DEBUG
        UIImage *orignalImage = [Scan_PixelBufferUtils pixelBuffer_Convert_image32BGRA:CVPixelBufferGetBaseAddress(pixelBuffer) width:CVPixelBufferGetWidth(pixelBuffer) height:CVPixelBufferGetHeight(pixelBuffer)];
        UIImage *clipImage = [Scan_PixelBufferUtils pixelBuffer_Convert_image32BGRA:clipImageBaseAddress width:clipParameters.clip_camera_w height:clipParameters.clip_camera_h];
#endif
        NSString *strCode = [NSString stringWithCString:(const char *)m_result encoding:NSUTF8StringEncoding];
        NSLog(@"_____%@___",strCode);
        
        //扫描识别成功，断开数据流连接 (数据流的断开 务必 在主线程中操作)
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        @weakify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self)
            [self.scanManager suspendScan];
            dispatch_semaphore_signal(semaphore);
        });
        
        if (_delegate && [_delegate respondsToSelector:@selector(scanVC_SuccessRecogize:barcodeInfo:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self playBeepSound];
                [_delegate scanVC_SuccessRecogize:self barcodeInfo:@{LY_BlackWhiteBarcode_Key:strCode,
                                                                     LY_BlackWhiteBarcodeType_Key:@(m_barType)}];
            });
        }
        
    }
    
    free(singleChannelBaseAddress);
    
    return RecognizeSuccess;
}


#pragma mark - 哔哔声
- (void)playBeepSound{
    NSString *strFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    
    NSURL *aFileURL = [NSURL fileURLWithPath:strFilePath isDirectory:NO];
    SystemSoundID soundId = 0;
    OSStatus status =  AudioServicesCreateSystemSoundID((__bridge  CFURLRef)aFileURL, &soundId);
    if (status == 0) {//成功创建
        AudioServicesPlaySystemSound(soundId);
    }
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
