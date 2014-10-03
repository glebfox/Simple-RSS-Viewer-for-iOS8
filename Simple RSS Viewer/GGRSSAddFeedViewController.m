//
//  GGRSSSettingsViewController.m
//  Simple RSS Viewer
//
//  Created by Gleb Gorelov on 23.09.14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSAddFeedViewController.h"
#import "GGRSSMasterViewController.h"

@interface GGRSSAddFeedViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UITextField *urlText;


@end

@implementation GGRSSAddFeedViewController

@synthesize url;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Осталось проверка от старой функциональности, когда вьюверу передавалась ссылка для редактирования.
    if (self.url != nil) {
        self.urlText.text = [self.url absoluteString];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Если была нажата любая кнопка отличная от Done (в данном случае Cancel), то возвращаем пустой url
    if (sender != self.doneButton) {
        self.url = nil;
        return;
    }
 
    // Если что то было введено в тектовом поле, то...
    if (self.urlText.text.length > 0) {
        // ... проверяем адрес на соответсиве полной форме и добавляем в начало недостающую часть
        if (![self.urlText.text hasPrefix:@"http://"]) {
            self.url = [NSURL URLWithString:[@"http://" stringByAppendingString:self.urlText.text]];
        }
        else
            self.url = [NSURL URLWithString:self.urlText.text];
    }
}

@end
