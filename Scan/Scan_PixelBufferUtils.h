//
//  Scan_PixelBufferUtils.h
//  Scan
//
//  Created by CircleLi on 2017/3/23.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//kCVPixelFormatType_32BGRA ，以下都是基于 32BGRA 的像素格式进行操作
//uint8_t == unsigned char(0~255) , sizeof(uint8_t)=1字节=8bit=2^8(0~255)

#define LY_BytesPerChannel sizeof(uint8_t)    //一个像素的格式为BGRA，4个通道，每个通道占的字节数为sizeof(uint8_t)
#define LY_ChannelCountsPer_BGRA_Pixel 4       //一个像素的格式为BGRA，4个通道



@interface Scan_PixelBufferUtils : NSObject

/**
 camera视角, 原图的PixelBuffer的基地址 (每个地址指向的内容,以每个像素的一个通道为单位,ps:一个BGRA像素,有4个通道) CVPixelBufferGetBaseAddress
 
 uint8_t == unsigned char(0~255) , sizeof(uint8_t)=1字节=8bit=2^8(0~255)
 */
+ (uint8_t *)getBaseAddress:(CVPixelBufferRef)pixelBuffer;


/**
 camera视角, 原图的PixelBuffer的width (以像素个数为单位)  CVPixelBufferGetWidth
 */
+ (size_t)getWidth:(CVPixelBufferRef)pixelBuffer;


/**
 camera视角, 原图的PixelBuffer的height (以像素个数为单位) CVPixelBufferGetHeight
 */
+ (size_t)getHeight:(CVPixelBufferRef)pixelBuffer;


/**
 camera视角, 原图的PixelBuffer 每行所有像素总共占的字节数 CVPixelBufferGetBytesPerRow ;  比如，这里对应我们设置的图像格式 32BGRA,所以1个像素有BGRA 4个通道，每个通道1个字节,这里我们也可以自己计算:width*4*sizeof(uint8_t)
 */
+ (size_t)getBytesPerRow:(CVPixelBufferRef)pixelBuffer;


/**
 原图的PixelBuffer 所有像素总共占的字节数 CVPixelBufferGetDataSize ;比如，这里对应我们设置的图像格式 32BGRA,所以1个像素有BGRA 4个通道，每个通道1个字节,这里我们也可以自己计算:width*height*4*sizeof(uint8_t) ， 但是通过CVPixelBufferGetDataSize取出的值似乎别手动计算多了8，不过影响不大。

 */
+ (size_t)getDataSize:(CVPixelBufferRef)pixelBuffer;


+ (uint8_t *)removeAlphaChannelWithPixelBufferAddress:(uint8_t *)baseAddress totalPixelCounts:(size_t)counts;



/*
 
 camera 视角 顺时针 旋转90°  为人类视角
 
 比如:AVCaptureSession.sessionPreset == AVCaptureSessionPreset1920x1080 , 图像大小1920(pixel)x1080(pixel)
 那么 width = 1920 , height = 1080 ,这是
 camera视角的 w1 x h1: width x height, 1920 x 1080
 
 fw = height
 fh = width
 
 但是人类视角  w2 x h2: fw x fh, 1080 x 1920
 
 这里frame 是以人类视角为准
 
 如果我们不想裁剪 ,得到全图: frame = (0,0,fw,fh)
 如果要裁剪,以人类视角来看, w2 取中间80% , h2 取中间50% , frame = (fw*0.1,fh*0.25,fw*0.8,fh*0.5)
 
  注：你需要负责free返回值
 
 */
+ (uint8_t *)clipPixelBuffer:(CVPixelBufferRef)pixelBuffer frame:(CGRect)frame;




/**
根据pixelBuffer的基地址，width ， height 转为image 
 
参数1: pixelBuffer基地址
参数2: pixelBufferWidth，像素为单位
参数3: pixelBufferHeight，像素为单位
 */
+ (UIImage *)pixelBuffer_Convert_image32BGRA:(uint8_t *)baseAddress width:(size_t)width height:(size_t)height;


/*
 根据image转为pixelBuffer
 
 CPU访问返回的CVPixelBufferRef 需要加锁， GPU访问返回的CVPixelBufferRef没有加锁的必要！
 你有责任调用CVPixelBufferRelease 释放返回值！
 */
+ (CVPixelBufferRef)image32BGRA_Convert_PixelBuffer:(UIImage *)image;



+ (uint8_t *)getSingleChannel_B_G_R_X_WithPixelBufferBaseAddress:(uint8_t *)baseAddress width:(size_t)width height:(size_t)height;


@end
