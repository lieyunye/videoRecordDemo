//
//  MenuViewController.m
//  videoRecord
//
//  Created by lieyunye on 2017/1/12.
//  Copyright © 2017年 lieyunye. All rights reserved.
//

#import "MenuViewController.h"

#import "ViewController.h"
#import "PipViewController.h"

static NSString *UpDownVideoMerge = @"UpDownVideoMerge";
static NSString *PipVideoMerge = @"PipVideoMerge";

@interface MenuViewController ()
@property (nonatomic, strong) NSMutableArray *datalist;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.datalist = [[NSMutableArray alloc] initWithCapacity:0];
    [self.datalist addObject:UpDownVideoMerge];
    [self.datalist addObject:PipVideoMerge];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableView class])];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datalist.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableView class]) forIndexPath:indexPath];
    cell.textLabel.text = self.datalist[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NSString *string = self.datalist[indexPath.row];
    if ([string isEqualToString:UpDownVideoMerge]) {
        ViewController *controller = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([ViewController class])];
        [self.navigationController pushViewController:controller animated:YES];
    }else if ([string isEqualToString:PipVideoMerge]){
        PipViewController *controller = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PipViewController class])];
        [self.navigationController pushViewController:controller animated:YES];

    }
}

@end
