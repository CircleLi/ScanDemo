//
//  Scan_PixelBufferUtils.m
//  Scan
//
//  Created by CircleLi on 2017/3/23.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "Scan_PixelBufferUtils.h"
#import <UIKit/UIKit.h>

static int count = 0;

@interface Scan_PixelBufferUtils ()


@end

@implementation Scan_PixelBufferUtils

+ (uint8_t *)getBaseAddress:(CVPixelBufferRef)pixelBuffer{
    /*
     检索出 PixelBuffer的基地址 , 前提要求是PixelBuffer的基地址已经加锁
     1.对于 chunky buffers(块缓冲), this will return a pointer to the pixel at 0,0 in the buffer
     2.对于 planar buffers(平面二维缓冲), this will return a pointer to a PlanarComponentInfo struct (defined in QuickTime)
     
     这里我们应该属于情况1, 返回 pointer(指针) 指向 整个PixelBuffer 处于(0,0)坐标的位置. 这个指针 就是 指向了PixelBuffer的基地址 ,  可以理解为 整张图片的(0,0)位置的那个像素点
     
     
     可访问图像数据,返回值是void * (泛型指针),我们这里强转为uint8_t == unsigned char(0~255),
     因为图像(BGRA 4个通道,每个通道可取0~255).
     这个指针指向像素位置为(0,0)
     数组排列:0-B,0-G,0-R,0-A;1-B,1-G,1-R,1-A;...;n-B,n-G,n-R,n-A
     
     sizeof(uint8_t) 为 1 , 表示1字节长度 , 1字节 == 8bit (0~255 范围)
     iOS中 typedef unsigned char uint8_t;
     
     sizeof(uint8_t *) 为4 ,表示4字节长度 , 这是 指针变量类型
     
     使用 uint8_t 的好处 : 直接看出 表示8bit (用来存储一个通道) , 0~255的范围 , 更加直观! 提示后面的 的每个通道所占的大小是 8bit , 刚好和 uint8_t中的8对应, 8bit=1byte. 这里直接用 void * 也没什么问题 , 主要是给了好看! 同时 uint8_t * 表示 指针指向的数据类型应该为uint8_t , 因为存储的数据 范围是0~255 , sizeof(uint8_t)=1byte=8bit , 2^8 就能表示0~255的范围
     
     所以本来是 返回值本来是 viod * , 这里我们强转为uint8_t *
     
     Xcode 断点调试器 , baseAddress的类型是 uint8_t *
     p *(baseAddress   ) 第一个像素的B通道
     p *(baseAddress +1) 第一个像素的G通道
     p *(baseAddress +2) 第一个像素的R通道
     p *(baseAddress +3) 第一个像素的A通道
     p *(baseAddress +4) 第二个像素的B通道
     p *(baseAddress +5) 第二个像素的G通道
     p *(baseAddress +6) 第二个像素的R通道
     p *(baseAddress +7) 第二个像素的A通道
     ........
     ........
     我们可以发现 有  '\a' , '\x1e' , '\xff' 这样的字符 , 我猜测着应该是表示 表示BGRA各个通道的值, 类似于'\a'这应该是ASCII码表对应的字符 , '\x1e'和'\xff'应该是一种十六进制的写法, 不论是 对应ASCII码表还是十六进制写法,  转换成十进制值的范围还是在0~255 , 因为BGRA每个通道范围也是0~255
     camera视角的baseAddress
     */
    return CVPixelBufferGetBaseAddress(pixelBuffer);
}

/*
 Get the PixelBuffer width and height , 和 AVCaptureSession.sessionPreset 设置的图像分辨率对应
 比如:AVCaptureSession.sessionPreset == AVCaptureSessionPreset1920x1080 , 图像大小1920(pixel)x1080(pixel)
 那么 width = 1920 , height = 1080
 camera视角的 w x h: width x height, 1920 x 1080
 */
+ (size_t)getWidth:(CVPixelBufferRef)pixelBuffer{
    return CVPixelBufferGetWidth(pixelBuffer);
}


+ (size_t)getHeight:(CVPixelBufferRef)pixelBuffer{
    return CVPixelBufferGetHeight(pixelBuffer);
}

+ (size_t)getBytesPerRow:(CVPixelBufferRef)pixelBuffer{
    /*
     sizeof(size_t) = 4 ,  4个字节 , 范围为0~(2^32-1) , 肯定够用来存储了 , 空间范围非常巨大 , 这里用size_t 仅仅是为了获得最够大的范围!
     size_t是标准C库中定义的，应为unsigned int，在64位系统中为 long unsigned int。
     
     Get the number of bytes per row for the pixel buffer
     由于每个像素点有BGRA 4个通道, 每个通道占一个字节, 所以一个像素点需要4个byte表示
     这个值的计算方式:
     AVCaptureSession.sessionPreset.width x 4byte
     
     比如:AVCaptureSession.sessionPreset == AVCaptureSessionPreset1920x1080 , 图像大小1920(pixel)x1080(pixel)
     那么 bytesPerRow = 1920x4byte = 7680byte , 所以每行的图像数据需要 7680个字节来存储
     camera视角的bytesPerRow
     */
    return CVPixelBufferGetBytesPerRow(pixelBuffer);
}


+ (size_t)getDataSize:(CVPixelBufferRef)pixelBuffer{
    //bytesPerRow x height , 但是实际似乎多了 8 。
    return CVPixelBufferGetDataSize(pixelBuffer);
}




/**
 去除pixelBuffer的Alpha通道
 
 @param baseAddress pixelBuffer基地址
 @param counts pixelBuffer的像素总个数(width*height)
 @return 去掉Alpha通道的新pixelBuffer的基地址 ， 你有责任free这个返回值
 */
+ (uint8_t *)removeAlphaChannelWithPixelBufferAddress:(uint8_t *)baseAddress totalPixelCounts:(size_t)counts{
    /*
     malloc() 在堆区分配一块指定大小的内存空间，用来存放数据。这块内存空间在函数执行完成后不会被初始化，它们的值是未知的。如果希望在分配内存的同时进行初始化，请使用 calloc() 函数。
     【返回值】分配成功返回指向该内存的地址，失败则返回 NULL。
     */
    //重新开辟空间来存储这个 只有 BGR通道的pixelBuffer
    uint8_t *pixelBufferWithAlphaChannel = (uint8_t *)malloc(counts*LY_BytesPerChannel*(LY_ChannelCountsPer_BGRA_Pixel-1));
    //因为原始pixelBuffer 每个像素有BGRA 4个通道 ,所有需要遍历每个像素来去掉A通道
    for (int i = 0; i<counts; i++) {
        uint8_t *dst = pixelBufferWithAlphaChannel + i*(LY_ChannelCountsPer_BGRA_Pixel-1);//拷贝接收，新pixelBuffer每个像素的起始地址
        uint8_t *src = baseAddress + i*LY_ChannelCountsPer_BGRA_Pixel;//原始pixelBuffer每个像素起始地址
        size_t   len = LY_BytesPerChannel*(LY_ChannelCountsPer_BGRA_Pixel-1);//因为原始pixelBuffer格式为BGRA，新pixelBuffer格式为BGR，所以拷贝原始pixelBuffer前3个通道的值，每个通道占1个字节，len表示拷贝的数据长度
        /*
         memcpy用来做内存拷贝，你可以拿它拷贝任何数据类型的对象，可以指定拷贝的数据长度
         功能:由src指向地址为起始地址的连续n个字节的数据复制到以destin指向地址为起始地址的空间内。
         返回值: 函数返回一个指向dest的指针。
         注:1.source和destin所指内存区域不能重叠，函数返回指向destin的指针。
         2.与strcpy相比，memcpy并不是遇到'\0'就结束，而是一定会拷贝完n个字节。
         */
        memcpy(dst, src, len);
    }
    return pixelBufferWithAlphaChannel;
}


/*
 首先,当我们竖直拿着iPhone拍照时, 我们需要知道,  程序中camera 获取的图像 和 previewLayer看到的图像 是一张图像, 但是方向不一样.
 previewLayer看到的图像 是相对于  人类视角
 camera 获取的图像 是相对于       camera视角.
 
 camera 获取的图像 需要顺时针旋转90° 才能变成 previewLayer看到的图像
 
 如果 sessionPreset = AVCaptureSessionPreset1920x1080
 那么 camera 获取的图像 w x h: 1920x1080 (像素为为单位)
 而  previewLayer 看到的图像 w x h:1080x1920
 
 我们发现 w和h颠倒了 , 这也正好 旋转的90° 相互照应!
 
 
 参数1: pixelBuffer , AVCaptureVideoDataOutput获取的 图像数据
 参数2: 人类视角,  frame为 基于人类视角图像裁剪的区域 , frame 的x ,y ,width , height 如果有小数,小数部分均会被忽略;
 
 如果 sessionPreset = AVCaptureSessionPreset1920x1080,
 那么PixelBuffer.width = 1920 ,    PixelBuffer.height = 1080
 
 那么 参数2: frame的x,y,width,height 是 基于 w x h = 1080x1920 的矩形来 裁剪!
 想要全图,不想裁剪的话 , frame = (0,0,1080,1920) , 这就是人类视角 ,对于一般手机而言: w < h
 
 
 注：你需要负责free返回值
 
 */
+ (uint8_t *)clipPixelBuffer:(CVPixelBufferRef)pixelBuffer frame:(CGRect)frame{
    //pixelBuffer的基本参数获取:baseAddress , width, height, bytesPerRow, dataSize
    uint8_t *baseAddress = [self getBaseAddress:pixelBuffer];//camera视角, 原图的PixelBuffer的基地址 (每个地址指向的内容,以每个像素的一个通道为单位,ps:一个BGRA像素,有4个通道) CVPixelBufferGetBaseAddress
    size_t width = [self getWidth:pixelBuffer];//camera视角, 原图的PixelBuffer的width (以像素个数为单位)  CVPixelBufferGetWidth
    size_t height = [self getHeight:pixelBuffer];//camera视角, 原图的PixelBuffer的height (以像素个数为单位) CVPixelBufferGetHeight
    
    
    //人类视角frame 转换为 camra视角frame = (fOriginX,fOriginY,fWidth,fHeight)
    size_t dstOriginX = (size_t)(frame.origin.y);//舍弃小数位数
    size_t dstOriginY = (size_t)(height - frame.size.width - frame.origin.x);//舍弃小数位数
    size_t dstWidth = (size_t)(frame.size.height);//舍弃小数位数
    size_t dstHeight = (size_t)(frame.size.width);//舍弃小数位数
    uint8_t *fBaseAddress = baseAddress+(dstOriginY*width + dstOriginX)*4;//裁剪的起始点, BRGA 4个通道. 所以是  像素个数 x 4.  地方
    
    /*
     malloc() 在堆区分配一块指定大小的内存空间，用来存放数据。这块内存空间在函数执行完成后不会被初始化，它们的值是未知的。如果希望在分配内存的同时进行初始化，请使用 calloc() 函数。
     【返回值】分配成功返回指向该内存的地址，失败则返回 NULL。
     */
    uint8_t *dstImageData = (uint8_t *)malloc(dstWidth*dstHeight*4*sizeof(uint8_t));//     像素的个数为dstWidth*dstHeight , 每个像素 存储需要的byte数为4. (B,G,R,A 每个通道需要1Byte的空间大小)
    uint8_t *sourceImageData = fBaseAddress;//裁剪矩形框的 origin的 起始地址
    for (int i=0; i<dstHeight; i++) { // 图像数据一行一行地copy, 总共有dstHeight行
        size_t len = dstWidth*4*sizeof(uint8_t);//每行copy的连续长度
        uint8_t *pSrc = sourceImageData + i*width*4;//裁剪区域每行的起始点计算 , 原图大小
        uint8_t *pDst = dstImageData+i*len;//拷贝接收 , 每行的起始点
        /*
         memcpy用来做内存拷贝，你可以拿它拷贝任何数据类型的对象，可以指定拷贝的数据长度
         功能:由src指向地址为起始地址的连续n个字节的数据复制到以destin指向地址为起始地址的空间内。
         返回值: 函数返回一个指向dest的指针。
         注:1.source和destin所指内存区域不能重叠，函数返回指向destin的指针。
         2.与strcpy相比，memcpy并不是遇到'\0'就结束，而是一定会拷贝完n个字节。
         */
        memcpy(pDst, pSrc, len);
    }
    return dstImageData;//裁剪之后的pixelbuffer的基地址
}


//camera视角,重新开辟的空间的 baseAddress 可以用此方法进行图片转换
+ (UIImage *)pixelBuffer_Convert_image32BGRA:(uint8_t *)baseAddress width:(size_t)width height:(size_t)height{
    UIImage *image = nil;
    if (1) { //Apple 官方推荐的API
        // Create a device-dependent RGB color space
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        /*
         Create a bitmap graphics context with the sample buffer data
         创建bitmap CGcontext ,  以BGRA 组成的pixel为例.
         参数1:  如果 data != NULL ,data指针 指向的内存 大小必须保证 >= (bytesPerRow * height) ; 如果data = NULL, 这个context关联的data 将自动 开辟空间 并且 随着context的销毁, data指向空间也将自动释放.
         参数2:  整个bitmap pixel的 width  (像素为单位)
         参数3:  整个bitmap pixel的 height (像素为单位)
         参数4:  这里 1个pixel 由BGRA 4个通道构成,  每个通道是一个component , 存储一个component需要8bit (0~255 的范围)   [8bit == 1byte]
         参数5:  bytesPerRow必须满足2个条件:  (1)每行bitmap pixel 的字节数 >= (width * 每个pixel所占字节数);(2)而且每行bitmap pixel 的字节数 必须为  每个pixel所占字节数的整数倍  [实际实验下来, 如果没有重新开辟图像空间，这里就使用原图的bytesPerRow , 如果不是可能带来图像错位混乱...]
         参数6:  每个像素的色彩空间 (色彩空间是描述颜色信息用的 , 常用的是RGB , 当然还有其他的)
         参数7:  bitmapInfo' specifies whether the bitmap should contain an
         alpha channel and how it's to be generated, along with whether the
         components are floating-point or integer.
         http://stackoverflow.com/questions/12949986/kcgimagealphapremultipliedfirst-and-kcgimagealphafirst
         http://stackoverflow.com/questions/20665615/cgbitmapinfo-value-performance-on-ios
         解释了 一些列枚举值的用法 ,  看得真是似懂非懂 .
         kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst 是一个经典组合 :
         首先 关于为什么选 kCGImageByteOrder32Little  而不是 kCGImageByteOrder16Little , 因为 我们有4个通道(4*8bit=32bit) , 所选32; 但是为什么选  kCGImageByteOrder32Little 而不选 kCGImageByteOrder32Big , 性能更加优化!
         
         关于为什么选 kCGImageAlphaPremultipliedFirst ,首先因为我们的格式是BGRA , 然后又是最佳性能问题!
         
         总之 为什么使用 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst 组合 :
         // makes system don't need to do extra conversion when displayed.
         
         反正我是有些看懵逼了! , 还是不太理解! 此坑待填
         
         */
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8*sizeof(uint8_t),
                                                     sizeof(uint8_t)*4*width, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        // Create a Quartz image from the pixel data in the bitmap graphics context
        CGImageRef quartzImage = CGBitmapContextCreateImage(context);
        
        
        // Create an image object from the Quartz image
        image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
        
        // Free up the context and color space
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        // Release the Quartz image
        CGImageRelease(quartzImage);
    }else{ //另一套API也行
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        /*
         创建一个可直接访问 的 data provider (这个 data provider 使用程序提供的data).你使用此函数去
         创建一个direct-access(直接存取) data provider (它还能使用callback函数 从程序中整个block中一次 读取数据 )
         
         Parameters
         info:
         一个指向任意类型data的pointer, 也可以传NULL. 当CoreGraphics.framework 调用了 此API 指定的
         releaseData 参数时, CoreGraphics.framework 会传递 这个info pointer 到releaseData回调函数的第一个参数.
         data:
         指向 (provider包含的)data数组 的 pointer.
         
         size:
         指定provider data包含的 byte数 大小.
         
         releaseData:
         A pointer to a release callback for the data provider, or NULL. Your release function is called when Core Graphics frees the data provider. For more information, see CGDataProviderReleaseDataCallback.
         Returns
         A new data provider. You are responsible for releasing this object using CGDataProviderRelease.
         */
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, width*height*4*sizeof(uint8_t), NULL);
        
        /*
         Description : 从data provider 提供的 data来创建 一个 bitmap image. 这个data provider 应该提供
         一个生肉data(未处理过的data,原始data) , 这个生肉data 需要满足指定格式(此API其他输入参数 指定的格式).
         为了使用 编码data (比如, 来自 一个 被URL-based data provider 指定的 file) , 请参考
         CGImageCreateWithJPEGDataProvider 和 CGImageCreateWithPNGDataProvider.
         关于更多 支持 pixel formats 的信息, 请参考Quartz 2D Programming Guide.
         
         width :  图片pixel的宽度 (单位为像素个数). camera 视角
         
         height : 图片pixel的高度 (单位为像素个数). camera 视角
         
         bitsPerComponent : 构成一个像素需要一些component , 存储每个component需要的bit 数 成为
         bitsPerComponent. 比如: 如果图片是 RGBA-32 格式, 那么 构成一个像素就是就需要R B G A 这4个
         component ,也就是4个通道, 一个像素总共占32bit , 那么每个component所占bit 数 为8bit ,
         bitsPerComponent = 8bit
         
         
         bitsPerPixel: 存储 图片每个pixel 所需要的 bit 数. bitsPerPixel >= bitsPerComponent x 构成每个像素的总components数.
         
         
         bytesPerRow : 存储 bitmap 每行pixel 所占的 字节(byte)数.  bytesPerRow = 每行的像素个数 x 构成每个像素的component数 .  camera 视角.    [实际实验下来, 不论你裁剪与否, 这里最好都是 使用原图的bytesPerRow , 如果不是可能带来图像错位混乱...]
         
         colorspace : image的色彩空间.  colorspace 是会被保留引用 , 当return时 , 你需要在在适当的位置 release colorspace , 避免内存泄露(memory leak).
         
         bitmapInfo :
         A constant that specifies whether the bitmap should contain an alpha channel and its relative location in a pixel, along with whether the components are floating-point or integer values. (一些枚举值的组合, 对于RGBA32-format来说, 最好的组合是kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst , 具体原因我也看得很懵逼!)
         
         provider :bitmap 的 数据源(data source).更多关于 支持的 数据格式(data formats) , 请看下面的说明. provider 是会被保留引用 , 当return时 , 你需要在在适当的位置 release provider , 避免内存泄露(memory leak).
         
         decode: image的 解码数组(decode array).如果你不想重新映射image的 color values , 请传入 NULL .
         对于image的color space中的每个color component(包括 alpha component , [颜色通道] ) ,
         一个decode array 提供 一对值 来表示 高值和低值的限制范围.例如, 在RBG color space 中 源image的
         decode array 总共包含6项 , 由一对red 的高低值 , 一对green的高低值 ,一对blue的高低值构成.当image被
         渲染时, CoreGraphics.framework 使用 线性变换 映射 原始的通道值(component value) 成指定高低值范围
         的一个相对数值 (高低值范围: 合适与目标color space的范围). image
         
         shouldInterpolate : 是否应该插值(插值运算). 当不进行插值时 , image 在输出设备(如果设备分辨率高于 image data的分辨率)上绘制时 , 也许 会发生锯齿效应或者像素化(马赛克化). image 水电气
         
         intent : rendering intent 常量 指定 CoreGraphics.framework 如何来处理 不位于graphics context
         的目标color space色域的colors. rendering intent 决定了 用于 从一个color space 映射到 另一个color space 的具体method. 更多关于rendering-intent 常量 的描述, 见CGColorRenderingIntent
         
         返回值: A new bitmap image. 你需要负责这个 bitmap image 的释放, 避免memory leak!
         
         */
        CGImageRef quartzImage = CGImageCreate(width, height, sizeof(uint8_t)*8, sizeof(uint8_t)*8*4, sizeof(uint8_t)*width*4, colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst, provider, NULL, true, kCGRenderingIntentDefault);
        image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
        
        //凡是带了Create的API , 都要有对应的 手动 Release
        CGColorSpaceRelease(colorSpace);
        CGDataProviderRelease(provider);
        CGImageRelease(quartzImage);
        
    }
    return image;
}

/*
 CPU访问返回的CVPixelBufferRef 需要加锁， GPU访问返回的CVPixelBufferRef没有加锁的必要！
 你有责任调用CVPixelBufferRelease 释放返回值！
 */
+ (CVPixelBufferRef)image32BGRA_Convert_PixelBuffer:(UIImage *)image{
    //返回bitmapImage的width，以像素为单位
    size_t pixelBufferWidth = CGImageGetWidth(image.CGImage);
    //返回bitmapImage的height，以像素为单位
    size_t pixelBufferHeight = CGImageGetHeight(image.CGImage);

    /*
     CF数据类型 与 NS数据类型之间的转换 (CFString与NSString , CFDictionary 与 NSDictornay 等等 )
     __bridge的用法详解！
     http://stackoverflow.com/questions/17227348/nsstring-to-cfstringref-and-cfstringref-to-nsstring-in-arc
     
     http://stackoverflow.com/questions/14854521/where-and-how-to-bridge
     */
    NSDictionary *options =
    @{
      //pixelBuffer是否与CGImage类型兼容
      (__bridge NSString *)kCVPixelBufferCGImageCompatibilityKey :
          [NSNumber numberWithBool:YES],
      //pixelBuffer是否与CoreGraphics的bitmapContext 兼容
      (__bridge NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey :
          [NSNumber numberWithBool:YES]
      };
    
    //准备创建的pixelBuffer
    CVPixelBufferRef outPixelBuffer = NULL;
    /**
     为一个给定的pixel size 和 pixel format 创建一个 pixel buffer。
     此函数基于描述在pixel的尺寸(width,height)、格式(formatType)和pixelBufferAttributes中扩展信息 ，来分配必需的内存 。
     此函数中其他参数 会 覆盖 pixelBufferAttributes中相同的属性。 比如，如果你在pixelBufferAttributes参数中定义kCVPixelBufferWidthKey和kCVPixelBufferHeightKey ，这些key所对应值将会被第二个参数width和第三个参数height 所覆盖。
     注：如果你需要去创建 和 释放 多个的 pixel buffer ，你应该使用 一个pixelBufferPool(详见CVPixelBufferPool)，CVPixelBufferPool能够更高效地复用pixelBuffer 内存。
     
     参数1: allocator （allocate /'æləket/ 分配器）
     allocator用于创建pixelBuffer。传入NULL 可以指定 DefaultAllocator (kCFAllocatorDefault 和 NULL 作用一样 )。
     
     参数2: width
     pixelBuffer的width，以像素为单位。
     
     参数3:height
     pixelBuffer的height，以像素为单位。
     
     参数4:pixelFormatType
     pixel format由各自的4字代码 定义 (类型 OSType)。
     
     参数5:pixelBufferAttributes （像素缓冲属性）
     一个pixelfBuffer的附加属性的dictionary。此参数为可选参数。更多的细节问题可以参考 Pixel Buffer Attribute Keys。
     
     参数6: pixelBufferOut
     在输出端，新创建的pixelBuffer。所有权遵循Create Rule (此函数带有Create字样，你需要自己手动释放新创建的pixelBuffer)。
     
     返回值: kCVReturnSuccess 表示success。
     
     
     为这个pixelBuffer开辟存储空间，但是还没关联image；也就是之后，还需要利用CoreGraphics将image的每个像素值绘制到pixelBuffer的空间去！
     */
    CVReturn allocateSuccess = CVPixelBufferCreate(
    kCFAllocatorDefault,
    pixelBufferWidth,
    pixelBufferHeight,
    kCVPixelFormatType_32BGRA,
    (__bridge CFDictionaryRef)options,
    &outPixelBuffer
                                                   );
    /*
     断言测试，allocateSuccess必须成功 且 outPixelBuffer必须有值(表示被创建了新的pixelBuffer); 如果断言不通过，将会抛出异常，crash！
     Xcode 中的 断言测试 ， Debug模式下默认开启，Realse版本中默认关闭的。
     */
    NSParameterAssert(allocateSuccess == kCVReturnSuccess && outPixelBuffer != NULL);
    
    /*
     对pixlebuffer的基地址(baseAddress)加锁.
     参数1: pixel buffer 基地址加锁, 保证系统内存可以访问这个 pixel buffer
     参数2:
     因为这里我们需要修改PixelBuffer，所以不能够传入 
     kCVPixelBufferLock_ReadOnly = 0x00000001 (只读,不允许修改)
     我们需要在PixelBuffer中写入数据, 由于没有其他枚举值，所以我们写一个0x00000000 应该就可以表示可写。
     
     在使用CPU访问pixel data 之前必须先调用 CVPixelBufferLockBaseAddress ，并且随后需要调用CVPixelBufferLockBaseAddress解锁
     
     在加锁成功之后 ,  后期解锁时 必须是相同的 lockFlags , 不对称加锁解锁的话, 可能会导致一些不可预知的行为发生.
     
     
     注：如果使用GPU访问，就没有必要 对基地址加锁和解锁 ，这还会带来性能问题
     
     
     我们这里还是以CPU来访问 pixel data ， 所以需要加锁
     
     */
    
    CVReturn lockSusccess = CVPixelBufferLockBaseAddress(outPixelBuffer, 0x00000000);
    if (lockSusccess == kCVReturnSuccess) {
        uint8_t *pixelBaseAddress = [self getBaseAddress:outPixelBuffer];
        //Create a device-dependent RGB color space
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        /*
         Create a Quartz image from the pixel data in the bitmap graphics context
         将CVPixelBuffer与bitmapContext关联
         */
        CGContextRef context = CGBitmapContextCreate(
        pixelBaseAddress,
        pixelBufferWidth,
        pixelBufferHeight,
        8*sizeof(uint8_t),
        [self getBytesPerRow:outPixelBuffer],
        rgbColorSpace,
        kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
                                                     );
        
        /**
         void CGContextDrawImage(CGContextRef c, CGRect rect, CGImageRef image);
         Description
         将一个image绘制到一个graphicsContext中,如果要去适应这个指定边界的rect参数，那么image可能会被不成比例地缩放。(比如,rect=(0,0,2*image.width,2*image.height),表示按比例放大1倍；rect=(0,0,2*image.width,image.height)，表示不成比例放大)
         
         
         Parameters
         参数1 c:在graphicsContext中，绘制image
         参数2 rect: 绘制image边界的用户空间的位置和尺寸
         参数3 image: 要绘制的image.
        
         在关联了CVPixelBuffer的bitmapContext中绘制image，从而将image的像素值绘制到PixelBuffer中。
         */
        CGContextDrawImage(
        context,
        CGRectMake(0, 0, pixelBufferWidth,pixelBufferHeight),
        image.CGImage
                           );
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
        //只有加锁成功，我们才进行解锁,并且LockFlag与加锁时保持一致。
        CVPixelBufferUnlockBaseAddress(outPixelBuffer, 0x00000000);
    }
    return outPixelBuffer;
}


/*
 旧的 image转 pixelBuffer， 但是这样仅仅返回baseAddress，无法通过baseAddress获取 width，height，format等信息。
 
 但是如果我们使用 image32BGRA_Convert_PixelBuffer 方法， 就能获得CVPixelBuffer类型数据，个人感觉CVPixelBuffer实际上是对baseAddress的一层封装，让其有了更多的信息(width,height,format等信息)
 
 */
+ (uint8_t *)oldImage32BGRA_Convert_PixelBuffer:(UIImage *)image{
    //返回bitmapImage的width，以像素为单位
    size_t pixelBufferWidth = CGImageGetWidth(image.CGImage);
    //返回bitmapImage的height，以像素为单位
    size_t pixelBufferHeight = CGImageGetHeight(image.CGImage);
    
    /**
     calloc()函数有两个参数,分别为元素的数目和每个元素的大小,这两个参数的乘积就是要分配的内存空间的大小.
     如果调用成功,函数malloc()和函数calloc()都将返回所分配的内存空间的首地址。 
     函数malloc()和函数calloc()的主要区别是前者不能初始化所分配的内存空间,而后者能。如果由malloc()函数分配的内存空间原来没有被使用过，则其中的每一位可能都是0;反之,如果这部分内存曾经被分配过,则其中可能遗留有各种各样的数据。也就是说，使用malloc()函数的程序开始时(内存空间还没有被重新分配)能正常进行,但经过一段时间(内存空间还已经被重新分配)可能会出现问题。
     */
    uint8_t *pixelBufferBaseAddress = (uint8_t *)calloc(pixelBufferWidth*pixelBufferHeight, sizeof(uint8_t));
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(
    pixelBufferBaseAddress,
    pixelBufferWidth,
    pixelBufferHeight,
    8*sizeof(uint8_t),
    pixelBufferWidth*4*sizeof(uint8_t),
    rgbColorSpace,
    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
                                                 );
    CGContextDrawImage(
    context,
    CGRectMake(0, 0, pixelBufferWidth,pixelBufferHeight),
    image.CGImage
                       );
    
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    
    return pixelBufferBaseAddress;
}





/**
 从PixelBuffer中获取 单通道的值
 pixelBuffer总共有4个通道[B,G,R,A]
 B:红色通道
 G:绿色通道
 R:红色通道
 A:透明度通道
 
 混合算法包识别 普通EN13条码、QRCode和快递码等，这些都属于黑白码; 所以 我们仅仅用 单个通道的值即可！
 
 提供的算法，识别：
 B:红色通道 值
 G:绿色通道 值
 R:红色通道 值
 X:灰度 值 = B*0.072169 + G*0.71516 + R*0.212671

 @param baseAddress pixelBuffer基地址
 @param width pixelBuffer宽度，以像素为单位
 @param height pixelBuffer高度，以像素为单位
 @return B/G/R/X 某个单个通道像素值， 你有责任free这个返回值！
 */
+ (uint8_t *)getSingleChannel_B_G_R_X_WithPixelBufferBaseAddress:(uint8_t *)baseAddress width:(size_t)width height:(size_t)height{
    //得到单通道的所有数据(也就是从某个某个像素，抽取一个通道[B,G,R,X]的值，)
    uint8_t *singleChannelData = (uint8_t *)malloc(width*height*sizeof(uint8_t));
    @synchronized (self) {//count自增1，保证线程安全
        count ++;
    }
    int iChannel = count & 0x0003;//iChannel在0，1，2，0，1，2...... 循环
    //iChanel 0-Blue 1-Green 2-Red 3-X(灰度值)
    if (iChannel == 3) {
        for (int i=0; i<width*height; i++)//pixel format is BGRA
            /*
             *4 表示每个像素有BRGA 4个通道:
             basebaseAddress[i*4 + 0] 表示B
             basebaseAddress[i*4 + 1] 表示G
             basebaseAddress[i*4 + 2] 表示R
             basebaseAddress[i*4 + 3] 表示A
             */
            singleChannelData[i] = baseAddress[i*4]*0.072169 + baseAddress[i*4+1]*0.71516 + baseAddress[i*4+2]*0.212671;
    }else{
        for (int i=0; i<width*height; i++)
        /*
         *4 表示每个像素有BRGA 4个通道:
         basebaseAddress[i*4 + 0] 表示B
         basebaseAddress[i*4 + 1] 表示G
         basebaseAddress[i*4 + 2] 表示R
         basebaseAddress[i*4 + 3] 表示A
         */
            singleChannelData[i] = baseAddress[i*4+iChannel];
    }
    return singleChannelData;
}





@end
