//
//  ViewController.m
//  CoreData
//
//  Created by whde on 16/3/16.
//  Copyright © 2016年 whde. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "PostCode.h"
#import <Alert/Alert.h>
@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UISearchBar *searchBar;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-20) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setScrollIndicatorInsets:UIEdgeInsetsMake(44, 0, 0, 0)];
    [self.view addSubview:_tableView];
    
    [self readData];
    
    // 键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];

}

- (void)readData {
    AppDelegate *del = [UIApplication sharedApplication].delegate;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PostCode"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"province" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"city" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"district" ascending:NO]];
    NSError *error = nil;
    NSArray *a = [del.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    if (!a || ([a isKindOfClass:[NSArray class]] && [a count] <= 0)) {
        // 添加数据到数据库
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *strPath = [[NSBundle mainBundle] pathForResource:@"城市邮编最终整理_方便导入数据库" ofType:@"txt"];
            NSString *text = [NSString stringWithContentsOfFile:strPath encoding:NSUTF16StringEncoding error:nil];
            NSArray *lineArr = [text componentsSeparatedByString:@"\n"];
            AppDelegate *del = [UIApplication sharedApplication].delegate;
            NSEntityDescription *description = [NSEntityDescription entityForName:@"PostCode" inManagedObjectContext:del.managedObjectContext];
            for (NSString *line in lineArr) {
                NSArray *items = [line componentsSeparatedByString:@"\t"];
                /*items[0],items[1], items[2], items[3], items[4], items[5]*/
                PostCode *postcode = [[PostCode alloc] initWithEntity:description insertIntoManagedObjectContext:del.managedObjectContext];
                postcode.id = items[0];
                postcode.province = items[1];
                postcode.city = items[2];
                postcode.district = items[3];
                postcode.cityId = ((NSString *)items[4]).length >=4 ? items[4]:[@"0" stringByAppendingString:items[4]];
                postcode.postCode = items[5];
            }
            [del saveContext];
            NSError *error = nil;
            NSArray *b = [del.managedObjectContext executeFetchRequest:request error:&error];
            if (error) {
                NSLog(@"%@", error);
            } else {
                _dataSource = [[NSMutableArray alloc] initWithArray:b];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_tableView reloadData];
                });
            }
        });
    } else {
        _dataSource = [[NSMutableArray alloc] initWithArray:a];
        [_tableView reloadData];
    }
    // 删除所有数据
    //        for (PostCode *postcode in a) {
    //            [del.managedObjectContext deleteObject:postcode];
    //        }
    //        [del saveContext];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 44)];
        _searchBar.delegate = self;
        _searchBar.placeholder = @"搜索";
    }
    return _searchBar;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataSource.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"POSTCODE";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == NULL) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    PostCode *postcode = [_dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@   %@   %@", postcode.province, postcode.city, postcode.district];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@   %@   %@   %@   %@   %@", postcode.id, postcode.province, postcode.city, postcode.district, postcode.cityId, postcode.postCode];
    return cell;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!searchText.length) {
        [self readData];
        return;
    }
    AppDelegate *del = [UIApplication sharedApplication].delegate;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PostCode"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"province" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"city" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"district" ascending:NO]];
    request.predicate = [NSPredicate predicateWithFormat:@"province CONTAINS %@ OR city CONTAINS %@ OR district CONTAINS %@ OR cityId CONTAINS %@ OR postCode CONTAINS %@ OR id CONTAINS %@", searchText, searchText, searchText, searchText, searchText, searchText];
    NSError *error = nil;
    NSArray *b = [del.managedObjectContext executeFetchRequest:request error:&error];
    _dataSource = [[NSMutableArray alloc] initWithArray:b];
    [_tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PostCode *postcode = [_dataSource objectAtIndex:indexPath.row];
    Alert *alert = [[Alert alloc] initWithTitle:@"详细" message:[NSString stringWithFormat:@"数据ID   :%@\n省份  :%@\n市  :%@\n区  :%@\n区号 :%@\n邮编 :%@\n", postcode.id, postcode.province, postcode.city, postcode.district, postcode.cityId, postcode.postCode] delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil];
    [alert setContentAlignment:NSTextAlignmentLeft];
    [alert setLineSpacing:5];
    [alert setFont:[UIFont systemFontOfSize:17]];
    [alert show];
}


#pragma mark - 键盘显示/隐藏
/**
 *  键盘显示
 *
 *  @param note
 */
- (void)keyBoardWillShow:(NSNotification *)note{
    CGRect rect = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView animateWithDuration:[note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        _tableView.frame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height-rect.size.height);
    }completion:^(BOOL finished) {
    }];
}

/**
 *  键盘隐藏
 *
 *  @param note
 */
- (void)keyBoardWillHide:(NSNotification *)note{
    [UIView animateWithDuration:[note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        _tableView.frame = CGRectMake(0, 20, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-20);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
