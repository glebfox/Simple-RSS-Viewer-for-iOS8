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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController class] == [GGRSSMasterViewController class]) {
        // Если была нажата любая кнопка отличная от Done (в данном случае Cancel), то возвращаем пустой url
        if (sender != self.doneButton) {
            self.url = nil;
            return;
        }
 
        // Если что то было введено в тектовом поле, то...
        if (self.urlText.text.length > 0) {
            NSString *stringURL = self.urlText.text;
            // ... проверяем адрес на соответсиве полной форме и добавляем в начало недостающую часть
            if (![stringURL hasPrefix:@"http://"]) {
                stringURL = [@"http://" stringByAppendingString:stringURL];
            }
            // На случай если в ссылке есть символы отличные от английских
            NSString *escapedString = [stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            self.url = [NSURL URLWithString:escapedString];
        }
    }
}

@end
