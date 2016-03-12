//
//  ViewController.m
//  XYQrCodeScanning
//
//  Created by 薛尧 on 15/8/11.
//  Copyright © 2015年 薛尧. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
///它是输入和输出的桥梁,主要协调input和output之间的数据传递
@property (nonatomic,strong)AVCaptureSession *captureSession;
///管理显示相机的类
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
///灯光是否打开标志
@property (nonatomic,assign)BOOL isLightOn;
@property (nonatomic,strong)NSTimer *timer;
///storyBoard中的距上约束
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lineTopContrait;
@property (nonatomic,assign)CGFloat number;
@end

@implementation ViewController

- (AVCaptureSession *)captureSession{
    if (_captureSession == nil) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}

- (AVCaptureVideoPreviewLayer *)previewLayer{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    }
    return _previewLayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.number = 1;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(animateineAction) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    
    self.isLightOn = NO;
    
    //得到当前系统版本
    CGFloat version = [UIDevice currentDevice].systemVersion.floatValue;
    if (version > 7.0f) {
        //苹果从iOS7以后才提供了摄像机扫描二维码功能
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] && [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            
            //开始扫描二维码
            [self startScan];
            
        }else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:@"相机不能使用" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
                [alertVC addAction:action];
                [self presentViewController:alertVC animated:YES completion:nil];
            });
        }
    }
}

#pragma mark -- 实现timer方法
- (void)animateineAction{
    if (self.lineTopContrait.constant < 350) {
        self.lineTopContrait.constant = 100 + self.number;
        self.number += 2;
    }else{
        self.lineTopContrait.constant = 100;
        self.number = 1;
    }
}

#pragma mark -- 打开灯光的 button
- (IBAction)lightUpButtonDidClicked:(id)sender {
    //获取手机的硬件设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //判断手机是否有闪光灯
    if ([device hasTorch]) {
        
        NSError *error = nil;
        [device lockForConfiguration:&error];
        
        if (self.isLightOn == NO) {
            [device setTorchMode:AVCaptureTorchModeOn];
            self.isLightOn = YES;
        }else{
            [device setTorchMode:AVCaptureTorchModeOff];
            self.isLightOn = NO;
        }
        
        [device unlockForConfiguration];
    }
}

#pragma mark -- 扫描二维码部分
- (void)startScan{
    //获取手机的硬件设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //输入设备,连接到上面获取到的硬件
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error == nil) {
        //桥梁添加一个输入
        [self.captureSession addInput:input];
        NSLog(@"");
    }
    
    //输出流(硬件的)
    AVCaptureMetadataOutput *outPut = [[AVCaptureMetadataOutput alloc] init];
    //桥梁添加一个输出
    [self.captureSession addOutput:outPut];
    
    //设置output
    dispatch_queue_t queue = dispatch_queue_create("com.xueyao", DISPATCH_QUEUE_CONCURRENT);
    
    [outPut setMetadataObjectsDelegate:self queue:queue];
    //设置支持二维码和条形码的扫描
    [outPut setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    //开始扫描
    [self.captureSession startRunning];
}

#pragma mark -- 扫描结果的代理回调方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    //现实中不管扫描到什么,只要一扫描到就停止扫描
    [self.captureSession stopRunning];
    
    //扫描二维码的结果 是一个字符串
    AVMetadataMachineReadableCodeObject *object = metadataObjects.firstObject;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([object.stringValue isEqualToString:@"打开微信"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"weixin:"]];//微
        }
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
