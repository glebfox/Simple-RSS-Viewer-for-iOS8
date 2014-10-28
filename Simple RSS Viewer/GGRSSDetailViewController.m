//
//  GGRSSDetailViewController.m
//  Simple RSS Viewer
//
//  Created by Gorelov on 9/19/14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSDetailViewController.h"
#import "NSString+HTML.h"

@interface GGRSSDetailViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSAttributedString *detailText;

@end

@implementation GGRSSDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
//    NSLog(@"Detail - viewDidLoad");
    [super viewDidLoad];
    
    self.textView.attributedText = self.detailText;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(GGRSSFeedItemInfo *)newDetailItem
{
//    NSLog(@"Detail - setDetailItem:");
    _detailItem = newDetailItem;
    [self configureDetailText];
    
    if (self.textView) {
//        NSLog(@"Detail - setDetailItem: - self.textView");
        self.textView.attributedText = self.detailText;
    } else {
//        NSLog(@"Detail - setDetailItem: - !self.textView");
    }
}

// ЗАполянет текстовую форму информацией по выбранной новости
- (void)configureDetailText
{
//    NSLog(@"Detail - configureDetailText");
    // Если информция есть, то ...
    if (self.detailItem) {
        // Создаем изменяемую форматную строку
        NSMutableAttributedString *detailInformation = [NSMutableAttributedString new];
        
        // Заголовок новости получает полужирное начертание с размером взятым из ресурсов (больше чем у остального текста)
        if (self.detailItem.title) {
            UIFont *font = [UIFont boldSystemFontOfSize:18];
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
            
            NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:[self.detailItem.title stringByConvertingHTMLToPlainText] attributes:attributes];
            
                                                                                                       
            [detailInformation appendAttributedString: titleString];
        }
        
        // Дата отобржается самым малееьким размером шрифта. Из ресурсов
        if (self.detailItem.date) {
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            
            UIFont *font = [UIFont systemFontOfSize:12];
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
            
            NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n\n%@\n\n",[formatter stringFromDate:self.detailItem.date]] attributes:attributes];
            
            
            [detailInformation appendAttributedString: dateString];
            
        } else {
            [detailInformation appendAttributedString: [[NSAttributedString alloc] initWithString: @"\n\n"]];
        }
        
        // Основной текст получает размер по умолчанию (из настроек формы, но можно и добавить ресурс). Дополнительно основной текст получает межстрочный интервал, для более приятногочтения.
        if (self.detailItem.summary) {
            
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.lineSpacing = 5;
            UIFont *font = [UIFont systemFontOfSize:16];
//            NSDictionary *attributes = [NSDictionary dictionaryWithObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:paragraphStyle, NSParagraphStyleAttributeName, font, NSFontAttributeName, nil];
            
            NSMutableAttributedString *summaryString = [[NSMutableAttributedString alloc] initWithString:[[self.detailItem.summary stringByConvertingHTMLToPlainText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] ] attributes:attributes];
            
            [detailInformation appendAttributedString: summaryString];
        }
        
        self.detailText = detailInformation;
        
        // Если в информации имеется ссылка на новость в интернете, то к форме добавляется кнопка для перехода
        if (self.detailItem.link) {
            UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString (@"DetailView_ButtonMore", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goLink:)];
            self.navigationItem.rightBarButtonItem = moreButton;
        }
    }
}

// Открытие ссылки на новость в браузере или любом другом зарегестрированном для этого приложении
- (IBAction)goLink:(id)sender
{
    if (self.detailItem.link) {
        [[UIApplication sharedApplication] openURL:self.detailItem.link];
    }
}

@end
