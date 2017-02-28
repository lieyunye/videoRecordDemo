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
#import "VideoRecordHelper.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *redoBtn;
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;




@property (nonatomic, strong) VideoRecordHelper *videoRecordHelper;
@property (nonatomic, strong) NSMutableArray *urlArray;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;

- (IBAction)startRecordAction:(id)sender;
- (IBAction)stopRecordAction:(id)sender;
- (IBAction)pauseRecordAction:(id)sender;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.urlArray = [NSMutableArray array];
    self.view.backgroundColor = [UIColor redColor];
    [self.navigationController.navigationBar setHidden:YES];
    self.videoRecordHelper = [[VideoRecordHelper alloc] init];
     __weak typeof(self) weakSelf = self;
    self.videoRecordHelper.durationCallback = ^(NSTimeInterval duration){
        weakSelf.durationLabel.text = [NSString stringWithFormat:@"%f",duration];
    };
    [self.videoRecordHelper configSession];
    self.videoRecordHelper.captureVideoPreviewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) / 2);
    [self.topView.layer addSublayer:self.videoRecordHelper.captureVideoPreviewLayer];
    
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(AVPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
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

- (IBAction)saveAction:(id)sender {
    
    
    NSURL *outputURL = ((AVURLAsset *)self.playerItem.asset).URL;
    if (outputURL == nil) {
        return;
    }
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL])  {
        
        [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"存档失败"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                }else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                    message:@"存档成功"
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            });
        }];
        
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)changeTopCameraAction:(id)sender {
    [self.videoRecordHelper changeCamera];
}



- (IBAction)redoAcion:(id)sender {
    self.durationLabel.text = @"";
    [self.urlArray removeAllObjects];
    [self.playerLayer removeFromSuperlayer];
    [self.topView.layer addSublayer:self.videoRecordHelper.captureVideoPreviewLayer];
    [self.player pause];
    self.player = nil;
}


- (IBAction)startRecordAction:(id)sender {

    if (self.videoRecordHelper.videoRecordState == VideoRecordStateUnkonw) {
        [self performSelector:@selector(stopTopViewRecording) withObject:nil afterDelay:10];
    }
    [self.videoRecordHelper startRecord];
}

- (IBAction)stopRecordAction:(id)sender {
     __weak typeof(self) weakSelf = self;
    [self.videoRecordHelper stopRecord:^(NSURL *url) {
        if (url) {
            [weakSelf.urlArray addObject:url];
        }
        if (weakSelf.urlArray.count == 2) {
            NSLog(@"mergeTwoVideosWithFirstAsset start");
            AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:self.urlArray.firstObject options:nil];
            AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:self.urlArray.lastObject options:nil];
            __weak typeof(self) weakSelf = self;
            [self.videoRecordHelper mergeTwoVideosWithFirstAsset:firstAsset secondAsset:secondAsset complete:^(NSString *url) {
                NSLog(@"mergeTwoVideosWithFirstAsset finished");
                [weakSelf playVideo:url];
            }];
        }
    }];
    
}

- (IBAction)pauseRecordAction:(id)sender {
    [self.videoRecordHelper pauseRecord];
}

- (void)stopTopViewRecording
{
    [self stopRecordAction:nil];
    if (self.videoRecordHelper.captureVideoPreviewLayer.superlayer == self.topView.layer) {
        [self.bottomView.layer addSublayer:self.videoRecordHelper.captureVideoPreviewLayer];
    }else {
        [self.videoRecordHelper.captureVideoPreviewLayer removeFromSuperlayer];
    }
}

- (void)playVideo:(NSString *)urlPath
{
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:urlPath]];
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = [UIScreen mainScreen].bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.playerLayer];
    [_player play];
    [self.view bringSubviewToFront:self.toolView];
}


- (void)AVPlayerItemDidPlayToEndTimeNotification:(NSNotification *)note
{
    AVPlayerItem * p = [note object];
    //关键代码
    [p seekToTime:kCMTimeZero];
    
    [self.player play];
}
@end
