//
//  VideoRecordHelper.h
//  videoRecord
//
//  Created by lieyunye on 2017/1/12.
//  Copyright © 2017年 lieyunye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MediaUtils.h"
@import UIKit;

@interface PipVideoRecordHelper : NSObject
@property (nonatomic, assign) VideoRecordState videoRecordState;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (nonatomic, copy) void (^durationCallback)(NSTimeInterval duration);
@property (nonatomic, copy) void (^imageCallback)(UIImage *image);


- (void)configSession;
- (void)startSeesion;
- (void)stopSeesion;
- (void)changeCamera;
- (void)startRecord;
- (void)stopRecord:(void (^)(NSURL *url))complete;
- (void)pauseRecord;
-(void) initVideoWriter;
- (void)mergeTwoVideosWithFirstAsset:(AVAsset *)firstAsset secondAsset:(AVAsset *)secondAsset complete:(void (^)(NSString *url))complete;

@end
