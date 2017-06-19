//
//  Scan_CaptureVideoManager.m
//  Scan
//
//  Created by CircleLi on 2017/3/22.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "Scan_CaptureVideoManager.h"
#import <UIKit/UIKit.h>
#import "AVCaptureSession+LY_Extension.h"
#import "AVCaptureDevice+LY_Extension.h"
#import "Scan_CaptureVideoMacros.h"
/**
 iOS捕获视频，并且将捕获的视频帧转化为UIImage对象的步骤：
 1. 创建一个 AVCaptureSession 对象,它是要用于协调从 AV 输入设备到输出设备的数据流。
 2. 找到你想要输入类型的 AVCaptureDevice 对象。
 3. 为设备创建一个 AVCaptureDeviceInput 对象。
 4. 创建一个 AVCaptureVideoDataOutput 去产生视频帧。
 5. 实现 AVCaptureVideoDataOutput 对象的代理方法, 去处理视频帧。
 6. 实现一个函数，将从代理方法收到的 CMSampleBuffer 转换为一个 UIImage 对象。
 */
@interface Scan_CaptureVideoManager ()
<AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureMetadataOutputObjectsDelegate>

//捕获设备，Device（摄像头、麦克风等物理设备）
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
//捕获输入，Input （从Device上捕获数据）
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;

//捕获输出，Output
@property (nonatomic, strong) AVCaptureOutput *captureOutput;

//捕获输出，Output (输出视频帧)
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
//捕获输出，Output (输出Metadata)
@property (nonatomic, strong) AVCaptureMetadataOutput *captureMetadataOutput;



/**
 1.捕获会话，Session ，用于协调 Input 和 Output 。
 2.startRunning应该在串行队列中执行以免阻塞主线程
 3.一个一个AVCaptureSession 可以装配 多个 inputs 和 outputs ,  甚至在AVCaptureSession 执行期间 , 可以装配或者卸载 inputs 和 outputs
 4.inputs和outputs之间由  AVCaptureConnection 连接 ，当一个session加上inputs 和 outputs 之后，会自动形成 AVCaptureConnection的连接
 5.可以使用AVCaptureConnection来 启用或者禁用 输入或者输出 数据流 ， 表现为连接断开或者连接
 */
@property (nonatomic, strong) AVCaptureSession *captureSession;


@end


static NSString * KeyPath_AvaibleMetadataObjectTypes = @"availableMetadataObjectTypes";

@implementation Scan_CaptureVideoManager

@synthesize scanAlgorithmType = _scanAlgorithmType;
@synthesize previewLayer = _previewLayer;

#pragma mark - LazyLoading


/*
 
 iPhone7 plus AV输入设备物理构成:
 1.前置广角镜头
 2.后置广角镜头
 3.后置长焦镜头, iPhone 7 Plus 才有
 4.麦克风
 
 iPhone7 plus AV输入设备软件构成:
 1.WideAngleCamera ,就是原来的那个摄像头,紧靠左边那个, 任何iPhone上一般都有 (这个WideAngleCamera,对应2个设备[Back Camera] 和 [Front Camera])
 2.TelephotoCamera ,在WideAngleCamera的右边 , 镜头比WideAngleCamera更长些, 目前仅iPhone7 Plus才有 , 对应设备为 [Back Telephoto Camera]
 3.DuoCamera (这是一个物理上不存在的摄像头, 是 WideAngleCamera + TelephotoCamera 联合使用带来的效果,看文档说 更屌) , 当然了 目前仅iPhone7 Plus 才有 , 对应设备为[Back iSight Duo Camera]
 4.Microphone , 麦克风, 对应设备为 [iPhone 麦克风]
 */

- (AVCaptureDevice *)captureDevice{
    if (!_captureDevice) {
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
            //找出所有可用的 AV inputDevice
            AVCaptureDeviceDiscoverySession *cdds = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:
                                                     @[AVCaptureDeviceTypeBuiltInMicrophone, //麦克风 , [iPhone 麦克风]
                                                       AVCaptureDeviceTypeBuiltInWideAngleCamera,//广角摄像头 [Back Camera] + [Front Camera]
                                                       AVCaptureDeviceTypeBuiltInTelephotoCamera,//长焦摄像头 [Back Telephoto Camera]
                                                       AVCaptureDeviceTypeBuiltInDuoCamera //双核摄像头 (广角摄像头和长焦摄像头 联合使用) [Back iSight Duo Camera]
                                                       ] mediaType:nil position:AVCaptureDevicePositionUnspecified];
            NSLog(@"%@",[cdds devices]);
            
            //WideAngleCamera ---->[Back Camera]
            _captureDevice = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack].devices.lastObject;
        }else{
            //找出所有可用的 AV inputDevice
            NSLog(@"%@", [AVCaptureDevice devices]);
            //WideAngleCamera ---->[Back Camera] , 这就是默认的AVMediaTypeVideo 输入设备
            _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            NSLog(@"%@",_captureDevice);
        }
    }
    return _captureDevice;
}

- (AVCaptureDeviceInput *)captureDeviceInput{
    if (!_captureDeviceInput) {
        NSError *error;
        //从指定 通过 输入捕获设备 提供 mediadataInput
        _captureDeviceInput  = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error]; //这里就会触发系统Alert,提示访问相机了
        if (error) {
            NSLog(@"%@",error);
        }
    }
    return _captureDeviceInput;
}

- (AVCaptureOutput *)captureOutput{
    if (!_captureOutput) {
        //多态
        switch (_scanAlgorithmType) {
            case ScanAlgorithm_System:
            {
                _captureOutput = self.captureMetadataOutput;
            }
                break;
            case ScanAlgorithm_Custom:
            {
                _captureOutput = self.captureVideoDataOutput;
            }
                break;
            default:
            {
                [NSException raise:@"未知的ScanAlgorithm" format:@"未知的ScanAlgorithm"];
            }
                break;
        }
    }
    return _captureOutput;
}

- (AVCaptureVideoDataOutput *)captureVideoDataOutput{
    if (!_captureVideoDataOutput) {
        //
        _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        /*
         .videoSettings 如果设置为nil , 之后才读取.videoSettings 不会是nil ,而是AVCaptureSession.sessionPreset的值 , 这就表示 以无压缩的格式 接收视频帧
         
         在iOS上, videoSettings 唯一支持的key 只有kCVPixelBufferPixelFormatTypeKey
         value只有3种:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange / kCVPixelFormatType_420YpCbCr8BiPlanarFullRange / kCVPixelFormatType_32BGRA
         */
        _captureVideoDataOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
        //丢弃掉延迟的视频帧,不再传给buffer queue
        _captureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        
        dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("com.CircleLi_VideoDataOutputQueue.www", DISPATCH_QUEUE_SERIAL);//必须是串行队列, 保证视频帧按顺序传递
        [_captureVideoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        
    }
    return _captureVideoDataOutput;

}

- (AVCaptureMetadataOutput *)captureMetadataOutput{
    if (!_captureMetadataOutput) {
        _captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        
        dispatch_queue_t metadataOutputQueue = dispatch_queue_create("com.CircleLi_MetadataOutputQueue.www", DISPATCH_QUEUE_SERIAL);//必须是串行队列, 保证对象按照顺序进行传送
        [_captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        
    }
    return _captureMetadataOutput;
}

- (AVCaptureSession *)captureSession{
    if (!_captureSession) {
        //
        _captureSession = [[AVCaptureSession alloc] init];
        @weakify(self)
        [_captureSession ly_configurationSession:^{
             @strongify(self)
            //session addInput
            if ([self.captureSession canAddInput:self.captureDeviceInput]) {
                [self.captureSession addInput:self.captureDeviceInput];
            }else{
                if (!TARGET_IPHONE_SIMULATOR) {//真机抛出异常
                    NSException *addInputFail = [NSException exceptionWithName:@"sessionAddInputException" reason:@"ly_throw" userInfo:nil];
                    @throw addInputFail;
                }
            }
            
            //sessionPreset
            if([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]){
                self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;//1080P
            }else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
                self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;//1080P
            }else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]){
                self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;//High
            }else{
                //weakSelf.captureSession.sessionPreset = deafault value (AVCaptureSessionPresetHigh)
            }
            
            
            //session addOutput
            if ([self.captureSession canAddOutput:self.captureOutput]) {
                [self.captureSession addOutput:self.captureOutput];
            }
        }];
    }
    return _captureSession;
}


- (AVCaptureVideoPreviewLayer *)previewLayer{
    if (!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        if (_previewLayer.connection.isVideoOrientationSupported) {
            //default value
            _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
        
    }
    return _previewLayer;
}


#pragma mark - LifeCycle

- (instancetype)initWithScanAlgorithmType:(ScanAlgorithm)scanAlgorithmType{
    self = [super init];
    if (self) {
        
        _scanAlgorithmType = scanAlgorithmType;
        
        //Apple说 availableMetadataObjectTypes 是 可以使用KVO的，但是这里并没有观察到值的变化；可能是自己KVO使用错误，此问题待考证？
        if (_scanAlgorithmType == ScanAlgorithm_System) {
            [self.captureMetadataOutput addObserver:self forKeyPath:KeyPath_AvaibleMetadataObjectTypes options:NSKeyValueObservingOptionNew context:nil];
        }
        /**
         因为只有当self.captureSession运行时，发挥发出AVCaptureSessionDidStartRunningNotification
         所以AVCaptureSessionDidStartRunningNotification 是和self.captureSession关联的
         仅仅接收来自self.captureSession 的 AVCaptureSessionDidStartRunningNotification
         */
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCaptureVideoDidStart:) name:AVCaptureSessionDidStartRunningNotification object:self.captureSession];
        
        if (_scanAlgorithmType == ScanAlgorithm_System) {
            if (self.captureMetadataOutput.availableMetadataObjectTypes.count > 0) {
                /**
                iOS6+，支持 AVMetadataObjectTypeFace
                iOS7+,支持各种 条码以及二维码
                
                 Note:
                 Available metadata object types are dependent on the capabilities of the AVCaptureInputPort to which this receiver's AVCaptureConnection is connected.
                 
                 我们需要确认 session添加好 inputs 和 outputs 之后，
                 captureMetadataOutput.availableMetadataObjectTypes才会有值
                 然后才可以设置captureMetadataOutput.metadataObjectTypes；否则，会导致crash！
                
                 
                 这里类型组合 ， 会影响到 扫码的效率问题:
                 https://developer.apple.com/library/content/technotes/tn2325/_index.html
                 Why is my 1-Dimensional barcode not detected at all locations in the image?
                 */
                self.captureMetadataOutput.metadataObjectTypes = @[
                                                                   AVMetadataObjectTypeEAN13Code,//普通商品条码
                                                                   AVMetadataObjectTypeCode128Code,//普通快递码
                                                                   AVMetadataObjectTypeQRCode//QR码(二维码)
                                                                   ];
                self.captureMetadataOutput.rectOfInterest = CGRectMake(0, 0, 1, 1);

            }
        }
    }
    return self;
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_captureMetadataOutput removeObserver:self forKeyPath:KeyPath_AvaibleMetadataObjectTypes];
}

#pragma mark - ScanControl
//启动扫描
- (void)startScan{

    //开启从input 到 ouput的数据流 connection
    [self.captureOutput connectionWithMediaType:AVMediaTypeVideo].enabled = YES;
#if !TARGET_IPHONE_SIMULATOR //仅仅真机才启动captureSession，否则可能带来模拟器crash！
    //启动相机捕获视频
    [self.captureSession startRunning];
#endif
}

//停止扫描
- (void)stopScan{
    /*
     关闭从input 到 ouput的数据流 connection， OutputSampleBuffer delegateMethod不再调用
     
     但是相机捕获的视频依然可以在previewLayer上动态显示
     */
    [self.captureOutput connectionWithMediaType:AVMediaTypeVideo].enabled = NO;
    /*
     1.关闭从input 到 ouput的数据流 connection， OutputSampleBuffer delegateMethod不再调用
     2.关闭相机捕获视频，相机捕获视频的最后一帧图像在previewLayer上固定显示！
     */
    [self.captureSession stopRunning];
}


- (void)suspendScan{ //即使暂停数据流连接,previewLayer依然呈现出捕获画面
    //断开数据连接
    [self.captureOutput connectionWithMediaType:AVMediaTypeVideo].enabled = NO;
}


- (void)resumeScan{
    //连接数据
    [self.captureOutput connectionWithMediaType:AVMediaTypeVideo].enabled = YES;
}


//设置扫描 聚焦模式
- (BOOL)setScan_FocusMode:(AVCaptureFocusMode)focusMode{
    BOOL isSupported = [self.captureDevice isFocusModeSupported:focusMode];
    if (isSupported) {
        @weakify(self)
        [self.captureDevice ly_configurationDevice:^{
            @strongify(self)
            self.captureDevice.focusMode = focusMode;
        }];
    }
    return isSupported;
}

//设置聚焦兴趣点，设置聚焦兴趣点时，聚焦模式为AVCaptureFocusModeContinuousAutoFocus
- (BOOL)setScan_FocusPointOfInterest:(CGPoint )focusPointOfInterest{
    BOOL isSupported = [self.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] && [self.captureDevice isFocusPointOfInterestSupported];
    if (isSupported) {
        @weakify(self)
        [self.captureDevice ly_configurationDevice:^{
            @strongify(self)
            self.captureDevice.focusPointOfInterest = focusPointOfInterest;
            self.captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }];
    }
    return isSupported;
}


/**
 设置扫描 手电筒模式
 
 对于一个有手电筒的设备，只有当该设备与一个正在运行的AVCaptureSession关联时，才能打开手电筒。
 */
- (BOOL)setScan_TorchMode:(AVCaptureTorchMode)torchMode{
    BOOL isSupported = [self.captureDevice isTorchModeSupported:torchMode];
    if (isSupported) {
        @weakify(self)
        [self.captureDevice ly_configurationDevice:^{
            @strongify(self)
            self.captureDevice.torchMode = torchMode;
        }];
    }
    return isSupported;
}


#pragma mark - NSNotification && KVO
//[session start]在哪个线程中调用， onCaptureVideoDidStart就会在哪个线程中触发！
- (void)onCaptureVideoDidStart:(NSNotification *)noti{
    if (_scanAlgorithmType == ScanAlgorithm_System) {
        //condition1: _rectOfInterest.width !=0  , _rectOfInterest.height != 0
        //condition2: _previewLayer.bounds 要包含 _rectOfInterest
        NSParameterAssert(
        !CGRectIsEmpty(_rectOfInterest) &&
        CGRectContainsRect(_previewLayer.bounds, _rectOfInterest)
                          );
        /*
        metadataOutputRectOfInterestForRect 计算出来的rect 应该和 [Scan_PixelBufferUtils clipPixelBuffer] 中的坐标系转换计算方式 类似 !
         
         camera视角 ， 人类视角 ，  相差90° 
         
         如果我们这里不用 metadataOutputRectOfInterestForRect 公式， 我也能自己纯手动计算metadataRectOfInterst
         
         */
        CGRect metadataRectOfInterst = [_previewLayer metadataOutputRectOfInterestForRect:_rectOfInterest];
        
        /*
         实测效果:
         仅当 captureMetadataOutput.metadataObjectTypes 中只有  只有一维条形码时 ，才能明显感觉到rectOfInterest的作用
         如果captureMetadataOutput.metadataObjectTypes 中 含有二维码，rectOfInterest设置之后的作用感觉不太明显，但是Apple说是性能优化了， 鬼知道呢？
         具体原因，参考链接:https://developer.apple.com/library/content/technotes/tn2325/_index.html
         */
        self.captureMetadataOutput.rectOfInterest = metadataRectOfInterst;
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:KeyPath_AvaibleMetadataObjectTypes]) {
        //
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
//视频 每一帧图像出来 都会调用此Delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    /**
     *  1.获取CMSampleBuffer的数目,0的话没有数据;正常都应该为1,每一帧图像
     *  2.CMSampleBuffer 有效
     *  3.CMSampleBuffer 数据已准备好
     三者条件均满足则视为一个 可用的sampleBuffer
     */
    if ((CMSampleBufferGetNumSamples(sampleBuffer) == 1) &&
        CMSampleBufferIsValid(sampleBuffer) &&
        CMSampleBufferDataIsReady(sampleBuffer)) {
        if (_delegate && [_delegate respondsToSelector:@selector(scan_CaptureVideoManager:outputPixelBuffer:)]) {
            
            /*
             typedef CVImageBufferRef CVPixelBufferRef;
             CVImageBufferRef == CVPixelBufferRef

             */
            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            /*
             对pixlebuffer的基地址(baseAddress)加锁.
             参数1: pixel buffer 基地址加锁, 保证系统内存可以访问这个 pixel buffer
             参数2: kCVPixelBufferLock_ReadOnly:PixelBuffer只读,不允许修改
             
             在使用CPU访问pixel data 之前必须先调用 CVPixelBufferLockBaseAddress ，并且随后需要调用CVPixelBufferLockBaseAddress解锁
             
             在加锁成功之后 ,  后期解锁时 必须是相同的 lockFlags , 不对称加锁解锁的话, 可能会导致一些不可预知的行为发生.
             
             
             注：如果使用GPU访问，就没有必要 对基地址加锁和解锁 ，这还会带来性能问题
             
             
             我们这里还是以CPU来访问 pixel data ， 所以需要加锁
             
             */
            CVReturn lockSuccess = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            if (lockSuccess == kCVReturnSuccess) {
                [_delegate scan_CaptureVideoManager:self outputPixelBuffer:pixelBuffer];
                //只有加锁成功，我们才进行解锁,并且LockFlag与加锁时保持一致。
                CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            }
        }
        
    }
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate
/*
 Delegates receive this message whenever the output captures and emits new objects, as specified by its metadataObjectTypes property.
 仅当ouput 捕获并且发出   一个由 metadataObjectTypes属性指定 的 MetadataObject 时， 才会调用此DelegateMethod
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count == 0) {
        return;
    }

    if (_delegate && [_delegate respondsToSelector:@selector(scan_CaptureMetadataManager:outputMetadataObjects:)]) {
        [_delegate scan_CaptureMetadataManager:self outputMetadataObjects:metadataObjects];
    }
}

@end






