//
//  DOHeaderView.m
//  Dopamine
//
//  Created by tomt000 on 04/01/2024.
//

#import "DOHeaderView.h"
#import "DOThemeManager.h"

@interface DOHeaderView ()

@property (nonatomic) UIImageView *logoView;

@end

@implementation DOHeaderView

-(id)initWithImage:(UIImage *)image subtitles:(NSArray<NSAttributedString *> *)subtitles {
    if (self = [super init]) {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.spacing = 2;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.alignment = UIStackViewAlignmentLeading;

        [self addSubview:stackView];

        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];

        // Personal build wordmark. Text scales more cleanly than modifying the
        // upstream logo asset and remains readable over every glass background.
        UILabel *wordmark = [[UILabel alloc] init];
        wordmark.translatesAutoresizingMaskIntoConstraints = NO;
        NSString *wordmarkText = @"Dopamine // RH";
        wordmark.attributedText = [[NSAttributedString alloc] initWithString:wordmarkText attributes:@{
            NSFontAttributeName: [UIFont monospacedSystemFontOfSize:36 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.80 green:0.94 blue:1.0 alpha:1.0],
            NSKernAttributeName: @0.8,
        }];
        wordmark.adjustsFontSizeToFitWidth = YES;
        wordmark.minimumScaleFactor = 0.76;
        wordmark.numberOfLines = 1;
        wordmark.layer.shadowColor = [UIColor colorWithRed:0.18 green:0.68 blue:1.0 alpha:1.0].CGColor;
        wordmark.layer.shadowOffset = CGSizeZero;
        wordmark.layer.shadowRadius = 12;
        wordmark.layer.shadowOpacity = 0.42;
        [stackView addArrangedSubview:wordmark];

        [NSLayoutConstraint activateConstraints:@[
            [wordmark.heightAnchor constraintEqualToConstant:46],
            [wordmark.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor],
        ]];

        //3 - Add our subtitles to our stack
        [subtitles enumerateObjectsUsingBlock:^(NSAttributedString *formatedText, NSUInteger idx, BOOL *stop) {
            UILabel *label = [[UILabel alloc] init];
            label.attributedText = formatedText;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            [stackView addArrangedSubview:label];
        }];

        self.translatesAutoresizingMaskIntoConstraints = NO;

        DOTheme *theme = [[DOThemeManager sharedInstance] enabledTheme];
        if (theme.titleShadow)
        {
            self.layer.shadowColor = [UIColor blackColor].CGColor;
            self.layer.shadowOffset = CGSizeZero;
            self.layer.shadowRadius = 30;
            self.layer.shadowOpacity = 0.3;
        }

    }
    return self;
}

@end
