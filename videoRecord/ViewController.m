//
//  ViewController.m
//  videoRecord
//
//  Created by lieyunye on 10/12/15.
//  Copyright © 2015 lieyunye. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MediaUtils.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/ALAssetsLibrary.h>

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *_session;
    AVCaptureDevice *_captureDeviceFront;
    AVCaptureDevice *_captureDeviceBack;
    AVCaptureDeviceInput *_captureDeviceInputFront;
    AVCaptureDeviceInput *_captureDeviceInputBack;
    
    AVCaptureVideoDataOutput *_captureVideoDataOutput;
    
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_assetWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterInputPixelBufferAdaptor;
    
    VideoRecordState _videoRecordState;
    
    CMTime _videoTimestamp;
    CMTime _timeOffset;


}

@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopReordBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseRecordBtn;

- (IBAction)startRecordAction:(id)sender;
- (IBAction)stopRecordAction:(id)sender;
- (IBAction)pauseRecordAction:(id)sender;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor redColor];
    
    _videoTimestamp = kCMTimeInvalid;
    _timeOffset = kCMTimeInvalid;

    
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    _session.sessionPreset = AVCaptureSessionPresetiFrame960x540;
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    captureVideoPreviewLayer.frame = self.view.bounds;
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:captureVideoPreviewLayer];
    
    _captureDeviceFront = [MediaUtils captureDeviceForPosition:AVCaptureDevicePositionFront];
    _captureDeviceBack = [MediaUtils captureDeviceForPosition:AVCaptureDevicePositionBack];
    
    _captureDeviceInputFront = [MediaUtils deviceInputWithDevice:_captureDeviceFront];
//    _captureDeviceInputBack = [MediaUtils deviceInputWithDevice:_captureDeviceBack];
    
    [_session addInput:_captureDeviceInputFront];
//    [_session addInput:_captureDeviceInputBack];
    
    _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_captureVideoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
     [_captureVideoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [_session addOutput:_captureVideoDataOutput];
    
    
    AVCaptureConnection *conn = [_captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [self initVideoWriter];

    [_session commitConfiguration];
    
    [self.view bringSubviewToFront:_startRecordBtn];
    [self.view bringSubviewToFront:_stopReordBtn];
    [self.view bringSubviewToFront:_pauseRecordBtn];
    
    [_session startRunning];

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startRecordAction:(id)sender {

    if (_videoRecordState == VideoRecordStateUnkonw) {
        _videoRecordState = VideoRecordStateRecording;
    }else {
        _videoRecordState = VideoRecordStateResumeRecord;
    }
}

- (IBAction)stopRecordAction:(id)sender {

    _videoRecordState = VideoRecordStateUnkonw;
    _timeOffset = kCMTimeInvalid;

    [_assetWriterInput markAsFinished];

    [_assetWriter finishWritingWithCompletionHandler:^{
        NSLog(@"finishWritingWithCompletionHandler");
    }];
    
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // 将临时文件夹中的视频文件复制到 照片 文件夹中，以便存取
    [library writeVideoAtPathToSavedPhotosAlbum:_assetWriter.outputURL
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    
                                    if (error) {
                                        
                                    }
                                    else {
                                        
                                    }
                                }];
    
    [self initVideoWriter];

}

- (IBAction)pauseRecordAction:(id)sender {

    _videoRecordState = VideoRecordStateInteruped;
}

-(void) initVideoWriter{
    
    CGSize size = CGSizeMake(540, 960);
    NSString *guid = [[NSUUID new] UUIDString];
    NSString *outputFile = [NSString stringWithFormat:@"video_%@.mp4", guid];
    NSString *outputDirectory = NSTemporaryDirectory();
    NSString *outputPath = [outputDirectory stringByAppendingPathComponent:outputFile];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        
    NSError *error = nil;
    
    //----initialize compression engine
    
    _assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL
                                                 fileType:AVFileTypeQuickTimeMovie
                                                    error:&error];
    
    NSParameterAssert(_assetWriter);
    
    if(error){
        NSLog(@"error = %@", [error localizedDescription]);
    }
    
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           
                                           [NSNumber numberWithDouble:1700000],AVVideoAverageBitRateKey,
                                           
                                           nil ];
    
    
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,AVVideoScalingModeResizeAspectFill,AVVideoScalingModeKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height],AVVideoHeightKey,videoCompressionProps, AVVideoCompressionPropertiesKey, nil];
    
    _assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
//    _assetWriterInput.transform = CGAffineTransformMakeRotation( ( 90 * M_PI ) / 180 );
    
    NSParameterAssert(_assetWriterInput);
    
    _assetWriterInput.expectsMediaDataInRealTime = YES;
    
    NSParameterAssert(_assetWriterInput);
    
    NSParameterAssert([_assetWriter canAddInput:_assetWriterInput]);
    
    
    
    if ([_assetWriter canAddInput:_assetWriterInput])
        NSLog(@"I can add this input");
    else{
        NSLog(@"i can't add this input");
    }
    
    
    [_assetWriter addInput:_assetWriterInput];
    
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        
        CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if( _videoRecordState == VideoRecordStateRecording && _assetWriter.status != AVAssetWriterStatusWriting  ){
            [_assetWriter startWriting];
            [_assetWriter startSessionAtSourceTime:lastSampleTime];
        }
        
        if (captureOutput == _captureVideoDataOutput){
            
            if (_videoRecordState == VideoRecordStateResumeRecord) {
                if (CMTIME_IS_VALID(lastSampleTime) && CMTIME_IS_VALID(_videoTimestamp)) {
                    CMTime offset = CMTimeSubtract(lastSampleTime, _videoTimestamp);
                    if (CMTIME_IS_INVALID(_timeOffset)) {
                        _timeOffset = offset;
                    }else {
                        _timeOffset = CMTimeAdd(_timeOffset, offset);
                    }
                }
                _videoRecordState = VideoRecordStateRecording;
            }
            
            if (_videoRecordState == VideoRecordStateInteruped) {
                
                _videoTimestamp = lastSampleTime;
                _videoRecordState = VideoRecordStatePausing;
            }
            
            if ( _assetWriter.status > AVAssetWriterStatusWriting ){
                NSLog(@"Warning: writer status is %ld", (long)_assetWriter.status);
                if( _assetWriter.status == AVAssetWriterStatusFailed){
                    NSLog(@"Error: %@", _assetWriter.error);
                }
                return;
            }
            
            if (_videoRecordState == VideoRecordStateRecording && [_assetWriterInput isReadyForMoreMediaData]){
                // adjust the sample buffer if there is a time offset
                CMSampleBufferRef bufferToWrite = NULL;
                if (CMTIME_IS_VALID(_timeOffset)) {
                    bufferToWrite = [MediaUtils createOffsetSampleBufferWithSampleBuffer:sampleBuffer withTimeOffset:_timeOffset];
                    if (!bufferToWrite) {
                        NSLog(@"error subtracting the timeoffset from the sampleBuffer");
                    }
                } else {
                    bufferToWrite = sampleBuffer;
                    CFRetain(bufferToWrite);
                }
                if( ![_assetWriterInput appendSampleBuffer:bufferToWrite] ){
                    
                    NSLog(@"Unable to write to video input");
                }else {
                    NSLog(@"already write vidio");                    
                }
                if (bufferToWrite) {
                    CFRelease(bufferToWrite);
                }
            }
        }
    }
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%s",__FUNCTION__);
}

@end
