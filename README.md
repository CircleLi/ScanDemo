# ScanDemo

## 讲解

ScanModule文件 为 扫码核心模块

3个重要类:

+ Scan_CaptureVideoManager.h  ---- 扫码相机管理类      
+ Scan_PixelBufferUtils.h ----- CVPixelBuffer处理类  （camera的视角 和 人类正常视角 的转换）
+ ScanViewController.h  -----  扫码界面  （外部使用ScanViewController可高度自定义 扫码界面以及 扫码限定区域）


## 如何使用？

+ 自行接入 ZXing 或者 ZBar  （适当修改ScanViewController 的 识别算法函数）
+ 参照Demo的 3个例子 （ 可以自行定义 全屏、半屏扫码界面 ， 添加自己App的一些个性化视图元素 ）
+ 使用ScanViewController时，最好将其 以一个 childVC 的关系附着在 具体的扫码界面 ，  从而保证  父子VC 的生命周期同步 , 因为ScanViewController已自动处理 相机的开闭 和 数据流的开闭。

## 亮点

+ 精准的 限定区域识别 （ScanViewController 中 recognizeLimitedArea属性设置）
+ 扫码嵌入NavigationController时 ， 反复地使用InteractivePopGesture ，不会带来卡顿。