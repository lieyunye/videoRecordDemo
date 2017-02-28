//
//  VideoRecordHelper.m
//  videoRecord
//
//  Created by lieyunye on 2017/1/12.
//  Copyright © 2017年 lieyunye. All rights reserved.
//

#import "VideoRecordHelper.h"


@interface VideoRecordHelper ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation VideoRecordHelper
{
    AVCaptureSession *_session;
    AVCaptureDevice *_captureDeviceFront;
    AVCaptureDevice *_captureDeviceBack;
    AVCaptureDeviceInput *_captureDeviceInputFront;
    AVCaptureDeviceInput *_captureDeviceInputBack;
    CameraDeviceInputState _cameraDeviceInputState;
    
    AVCaptureVideoDataOutput *_captureVideoDataOutput;
    
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_assetWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterInputPixelBufferAdaptor;
    
    
    CMTime _videoTimestamp;
    CMTime _startTimestamp;
    CMTime _timeOffset;
    BOOL _isSessionRuning;
     
}

- (void)dealloc
{
    NSLog(@"dealloc");
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer
{
    if (_captureVideoPreviewLayer == nil) {
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _captureVideoPreviewLayer;
}

- (void)configSession
{
    _videoTimestamp = kCMTimeInvalid;
    _timeOffset = kCMTimeInvalid;
    
    
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    _session.sessionPreset = AVCaptureSessionPresetiFrame960x540;
    
    _captureDeviceFront = [MediaUtils captureDeviceForPosition:AVCaptureDevicePositionFront];
    _captureDeviceBack = [MediaUtils captureDeviceForPosition:AVCaptureDevicePositionBack];
    
    _captureDeviceInputFront = [MediaUtils deviceInputWithDevice:_captureDeviceFront];
    _captureDeviceInputBack = [MediaUtils deviceInputWithDevice:_captureDeviceBack];
    
//    if (_captureDeviceFront) {
//        [_session addInput:_captureDeviceInputFront];
//    _cameraDeviceInputState = CameraDeviceInputStateFront;
//    }
    
    if (_captureDeviceInputBack) {
        [_session addInput:_captureDeviceInputBack];
        _cameraDeviceInputState = CameraDeviceInputStateBack;
    }
    
    _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_captureVideoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    [_captureVideoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if (_captureVideoDataOutput) {
        [_session addOutput:_captureVideoDataOutput];
    }
    
    
    AVCaptureConnection *conn = [_captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [_session commitConfiguration];
    [self startSeesion];

}

- (void)startSeesion
{
    if (_isSessionRuning == YES) {
        return;
    }
    [_session startRunning];
    _isSessionRuning = YES;
}

- (void)stopSeesion
{
    _isSessionRuning = NO;
    [_session stopRunning];

}

- (void)changeCamera
{
    [_session beginConfiguration];
    if (_cameraDeviceInputState == CameraDeviceInputStateBack) {
        [_session removeInput:_captureDeviceInputBack];
        _session.sessionPreset = AVCaptureSessionPresetiFrame960x540;
        if ([_session canAddInput:_captureDeviceInputFront] == NO) {
            return;
        }
        
        _cameraDeviceInputState = CameraDeviceInputStateFront;
        [_session addInput:_captureDeviceInputFront];
        AVCaptureConnection *conn = [_captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        [conn setVideoMirrored:YES];
    }else {
        [_session removeInput:_captureDeviceInputFront];
        _session.sessionPreset = AVCaptureSessionPresetiFrame960x540;
        if ([_session canAddInput:_captureDeviceInputBack] == NO) {
            return;
        }
        _cameraDeviceInputState = CameraDeviceInputStateBack;
        [_session addInput:_captureDeviceInputBack];
        AVCaptureConnection *conn = [_captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        [conn setVideoMirrored:NO];
    }
    [_session commitConfiguration];
}

- (void)startRecord
{
    
    if (_videoRecordState == VideoRecordStateUnkonw) {
        _startTimestamp = kCMTimeInvalid;
        _videoRecordState = VideoRecordStateRecording;
        [self initVideoWriter];
    }else {
        _videoRecordState = VideoRecordStateResumeRecord;
    }
}

- (void)stopRecord:(void (^)(NSURL *url))complete
{
    
    _videoRecordState = VideoRecordStateUnkonw;
    _timeOffset = kCMTimeInvalid;
    
    [_assetWriterInput markAsFinished];
    [_assetWriter finishWritingWithCompletionHandler:^{
        NSLog(@"finishWritingWithCompletionHandler");
        if (complete) {
            complete(_assetWriter.outputURL);
        }
    }];
}

- (void)pauseRecord
{
    
    _videoRecordState = VideoRecordStateInteruped;
}


-(void) initVideoWriter
{
    CGSize size = CGSizeZero;
    if ([_session.sessionPreset isEqualToString: AVCaptureSessionPresetiFrame960x540]) {
        size = CGSizeMake(540, 960);
    }else {
        size = CGSizeMake(1080, 1920);
    }
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
    
    
    
    CGFloat cleanApertureWidth = size.width;
    CGFloat cleanApertureHeight = size.height / 2.0;
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                @(cleanApertureWidth), AVVideoCleanApertureWidthKey,
                                                @(cleanApertureHeight), AVVideoCleanApertureHeightKey,
                                                @0, AVVideoCleanApertureHorizontalOffsetKey,
                                                @(0), AVVideoCleanApertureVerticalOffsetKey,
                                                nil];
    
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           
                                           [NSNumber numberWithDouble:1700000],AVVideoAverageBitRateKey,
                                           videoCleanApertureSettings,
                                           AVVideoCleanApertureKey,
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
            _startTimestamp = lastSampleTime;
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
                    CMTime offset = CMTimeSubtract(lastSampleTime, _startTimestamp);
                    NSLog(@"already write vidio %f",CMTimeGetSeconds(offset));
                    if (self.durationCallback) {
                        self.durationCallback(CMTimeGetSeconds(offset));
                    }
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

- (void)mergeTwoVideosWithFirstAsset:(AVAsset *)firstAsset secondAsset:(AVAsset *)secondAsset complete:(void (^)(NSString *url))complete
{
    
    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *firstLayerInstruction = nil;
    AVMutableVideoCompositionLayerInstruction *secondlayerInstruction = nil;
    CGAffineTransform t1;
    AVMutableComposition *mutableComposition = [[AVMutableComposition alloc] init];
    [self configMutableComposition:mutableComposition asset:firstAsset];
    [self configMutableComposition:mutableComposition asset:secondAsset];
    AVAssetTrack *assetVideoTrack = nil;
    if ([[firstAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [firstAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height * 2);
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]);
    firstLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(mutableComposition.tracks)[0]];
    secondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(mutableComposition.tracks)[1]];
    t1 = CGAffineTransformMakeTranslation(0, assetVideoTrack.naturalSize.height);
    [secondlayerInstruction  setTransform:t1 atTime:kCMTimeZero];
    instruction.layerInstructions = @[firstLayerInstruction,secondlayerInstruction];
    mutableVideoComposition.instructions = @[instruction];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:@"mergeVideo.mov"];
    
    [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    [exporter setVideoComposition:mutableVideoComposition];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             switch (exporter.status) {
                 case AVAssetExportSessionStatusCompleted:
                     // Step 3
                     // Notify AVSEViewController about export completion
                     if (complete) {
                         complete(myPathDocs);
                     }
                     break;
                 case AVAssetExportSessionStatusFailed:
                     NSLog(@"Failed:%@",exporter.error);
                     if (complete) {
                         complete(nil);
                     }
                     break;
                 case AVAssetExportSessionStatusCancelled:
                     NSLog(@"Canceled:%@",exporter.error);
                     if (complete) {
                         complete(nil);
                     }
                     break;
                 default:
                     break;
             }
         });
     }];
}

- (void)configMutableComposition:(AVMutableComposition *)mutableComposition asset:(AVAsset *)asset
{
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    CMTime insertionPoint = kCMTimeZero;
    NSError *error = nil;
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    }

    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
    }
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
    }
}

@end
