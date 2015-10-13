//
//  MediaUtils.h
//  videoRecord
//
//  Created by lieyunye on 10/12/15.
//  Copyright © 2015 lieyunye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


typedef enum :NSUInteger {
    VideoRecordStateUnkonw,
    VideoRecordStateRecording,
    VideoRecordStateResumeRecord,
    VideoRecordStatePausing,
    VideoRecordStateInteruped,
    VideoRecordStateStoped,
} VideoRecordState;

@interface MediaUtils : NSObject
+ (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position;
+ (AVCaptureDeviceInput *)deviceInputWithDevice:(AVCaptureDevice *)device;
+ (CMSampleBufferRef)createOffsetSampleBufferWithSampleBuffer:(CMSampleBufferRef)sampleBuffer withTimeOffset:(CMTime)timeOffset;

@end
