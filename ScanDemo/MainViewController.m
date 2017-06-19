//
//  MainViewController.m
//  ScanDemo
//
//  Created by CircleLi on 2017/6/16.
//  Copyright © 2017年 CircleCircle. All rights reserved.
//

#import "MainViewController.h"
#import "NavigationFullScreenScanViewController.h"
#import "NavigationHalfScreenScanViewController.h"
#import "PresentFullScreenScanViewController.h"

typedef NS_ENUM(NSInteger, JumpVC) {
    JumpVC_NavigationFullScreenScan = 0,
    JumpVC_NavigationHalfScreenScan,
    JumpVC_PresentFullScreenScan,
};


@interface MainViewController ()
<UITableViewDelegate,
UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

static NSString *reuseID = @"cellID";

@implementation MainViewController

#pragma mark - LazyLoaing
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64.0f, SCREEN_WIDTH, SCREEN_HEIGHT - 64.0f) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseID];
    }
    return _tableView;
}

#pragma mark - LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.tableView];
    
}


#pragma mark - UITableViewDelegate & UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    
    switch (indexPath.row) {
        case JumpVC_NavigationFullScreenScan:
        {
            cell.textLabel.text = @"NavigationFullScreenScan+🌈";
        }
            break;
        case JumpVC_NavigationHalfScreenScan:
        {
            cell.textLabel.text = @"NavigationHalfScreenScan";
        }
            break;
        case JumpVC_PresentFullScreenScan:
        {
            cell.textLabel.text = @"PresentFullScreenScan";
        }
            break;
        default:
            break;
    }
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case JumpVC_NavigationFullScreenScan:
        {
            NavigationFullScreenScanViewController *navFullScanVC = [[NavigationFullScreenScanViewController alloc] init];
            navFullScanVC.navigationItem.title = @"NavigationFullScreenScan+🌈";
            [self.navigationController pushViewController:navFullScanVC animated:YES];
            
        }
            break;
        case JumpVC_NavigationHalfScreenScan:
        {
            NavigationHalfScreenScanViewController *navHalfScanVC = [[NavigationHalfScreenScanViewController alloc] init];
            navHalfScanVC.navigationItem.title = @"NavigationHalfScreenScan";
            [self.navigationController pushViewController:navHalfScanVC animated:YES];
        }
            break;
        case JumpVC_PresentFullScreenScan:
        {
            PresentFullScreenScanViewController *presentFullScanVC = [[PresentFullScreenScanViewController alloc] init];
            [self presentViewController:presentFullScanVC animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
