//
//  PipViewController.m
//  videoRecord
//
//  Created by lieyunye on 2017/1/13.
//  Copyright © 2017年 lieyunye. All rights reserved.
//

#import "PipViewController.h"
#import "PipVideoRecordHelper.h"
#import "ASScreenRecorder.h"

@interface PipViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *pipImageView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (nonatomic, strong) PipVideoRecordHelper *pipVideoRecordHelper;
@property (weak, nonatomic) IBOutlet UIImageView *videoImageView;

@end

@implementation PipViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController.navigationBar setHidden:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:self.containerView];
    [self.view bringSubviewToFront:self.toolView];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.pipVideoRecordHelper = [[PipVideoRecordHelper alloc] init];
     __weak typeof(self) weakSelf = self;
    self.pipVideoRecordHelper.imageCallback = ^(UIImage *image){
        weakSelf.pipImageView.image = image;
        weakSelf.videoImageView.image = image;
    };
    
    
    [self.pipVideoRecordHelper configSession];
    self.pipVideoRecordHelper.captureVideoPreviewLayer.frame = self.view.bounds;
    
//    CGFloat replicatorViewHeight = 100;
//    CAReplicatorLayer *replicatorLayer = [CAReplicatorLayer layer];
//    replicatorLayer.frame = CGRectMake(0, 0, 100, replicatorViewHeight);
//    replicatorLayer.instanceCount = 2;
//    replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0.0, replicatorViewHeight, 0.0);
//    replicatorLayer.masksToBounds = YES;
//    [replicatorLayer addSublayer:self.pipVideoRecordHelper.captureVideoPreviewLayer];
    
//    [self.view.layer addSublayer:self.pipVideoRecordHelper.captureVideoPreviewLayer];
//    [self.view.layer addSublayer:replicatorLayer];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    //    maskLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 100, 150)].CGPath;
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    maskLayer.strokeColor = [UIColor redColor].CGColor;
    maskLayer.frame = self.pipImageView.bounds;
    maskLayer.contents = (id)[UIImage imageNamed:@"bottle_bg"].CGImage;
    maskLayer.contentsCenter = CGRectMake(0.5, 0.5, 0.1, 0.1);
    maskLayer.contentsScale = [UIScreen mainScreen].scale;
    self.pipImageView.layer.mask = maskLayer;
}


- (IBAction)startRecordAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    ASScreenRecorder *recorder = [ASScreenRecorder sharedInstance];
    recorder.durationCallback = ^(NSTimeInterval duration){
        weakSelf.timeLabel.text = [NSString stringWithFormat:@"%f",duration];
        if (duration > 10) {
            ASScreenRecorder *recorder = [ASScreenRecorder sharedInstance];
            [recorder stopRecordingWithCompletion:^{
                NSLog(@"Finished recording");
            }];
        }
    };
    recorder.recordView = self.containerView;
    if (recorder.isRecording) {
        
    } else {
        [recorder startRecording];
        NSLog(@"Start recording");
    }
}



- (IBAction)changeCameraAction:(id)sender {
    ASScreenRecorder *recorder = [ASScreenRecorder sharedInstance];
    if (recorder.isRecording == NO) {
        [self.pipVideoRecordHelper changeCamera];
    }
}

@end
