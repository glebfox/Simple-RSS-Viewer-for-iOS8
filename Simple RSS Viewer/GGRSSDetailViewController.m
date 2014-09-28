//
//  GGRSSDetailViewController.m
//  Simple RSS Viewer
//
//  Created by Gorelov on 9/19/14.
//  Copyright (c) 2014 Gleb Gorelov. All rights reserved.
//

#import "GGRSSDetailViewController.h"
#import "GGRSSDimensionsProvider.h"
#import "NSString+HTML.h"

@interface GGRSSDetailViewController ()

@property GGRSSDimensionsProvider *dimensionsProvider;

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
    [super viewDidLoad];
    
    self.dimensionsProvider = [GGRSSDimensionsProvider sharedInstance];
    
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(MWFeedItem *)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        //[self configureView];
    }
}

- (void)configureView
{
    if (self.detailItem) {
        NSMutableAttributedString *detailInformation = [NSMutableAttributedString new];
        
        if (self.detailItem.title) {
            UIFont *font = [UIFont boldSystemFontOfSize:[self.dimensionsProvider dimensionByName:@"DetailView_TitleSize"]];
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
            
            NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:[self.detailItem.title stringByConvertingHTMLToPlainText] attributes:attributes];
            
                                                                                                       
            [detailInformation appendAttributedString: titleString];
        }
        
        if (self.detailItem.date) {
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            
            UIFont *font = [UIFont systemFontOfSize:[self.dimensionsProvider dimensionByName:@"DetailView_DateSize"]];
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
            
            NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n\n%@\n\n",[formatter stringFromDate:self.detailItem.date]] attributes:attributes];
            
            
            [detailInformation appendAttributedString: dateString];
            
        }
        
        if (self.detailItem.summary) {
            
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.lineSpacing = [self.dimensionsProvider dimensionByName:@"DetailView_SummaryLineSpacing"];
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
            
            NSMutableAttributedString *summaryString = [[NSMutableAttributedString alloc] initWithString:[[self.detailItem.summary stringByConvertingHTMLToPlainText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] ] attributes:attributes];
            
            [detailInformation appendAttributedString: summaryString];
        }
        
        self.textView.attributedText = detailInformation;
        
        if (self.detailItem.link) {
            UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString (@"DetailView_ButtonMore", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goLink:)];
            self.navigationItem.rightBarButtonItem = moreButton;
        }
    }
}

- (IBAction)goLink:(id)sender
{
    if (self.detailItem.link) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.detailItem.link]];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
