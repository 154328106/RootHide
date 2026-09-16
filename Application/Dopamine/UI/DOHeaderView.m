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
@property (nonatomic, readwrite) UILabel *uptimeLabel;

@end

@implementation DOHeaderView

-(id)initWithImage:(UIImage *)image subtitles:(NSArray<NSAttributedString *> *)subtitles {
    if (self = [super init]) {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.spacing = 2;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.alignment = UIStackViewAlignmentCenter;

        // 顶部：外大框 + 内小框（双层），文字在内小框里。提亮的通透蓝。
        UIView *outerBg = [[UIView alloc] init];
        outerBg.translatesAutoresizingMaskIntoConstraints = NO;
        outerBg.userInteractionEnabled = NO;
        outerBg.backgroundColor = [UIColor colorWithRed:0.22 green:0.52 blue:0.80 alpha:0.14];
        outerBg.layer.cornerRadius = 26;
        outerBg.layer.cornerCurve = kCACornerCurveContinuous;
        outerBg.layer.borderWidth = 1.0;
        outerBg.layer.borderColor = [UIColor colorWithRed:0.80 green:0.95 blue:1.0 alpha:0.42].CGColor;
        [self addSubview:outerBg];

        UIView *cardBg = [[UIView alloc] init];
        cardBg.translatesAutoresizingMaskIntoConstraints = NO;
        cardBg.userInteractionEnabled = NO;
        cardBg.backgroundColor = [UIColor colorWithRed:0.30 green:0.62 blue:0.92 alpha:0.24];
        cardBg.layer.cornerRadius = 18;
        cardBg.layer.cornerCurve = kCACornerCurveContinuous;
        cardBg.layer.borderWidth = 1.0;
        cardBg.layer.borderColor = [UIColor colorWithRed:0.80 green:0.96 blue:1.0 alpha:0.48].CGColor;
        [self addSubview:cardBg];

        [self addSubview:stackView];

        [NSLayoutConstraint activateConstraints:@[
            // 外大框：贴 header 边（左右各缩 6）
            [outerBg.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0],
            [outerBg.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0],
            [outerBg.topAnchor constraintEqualToAnchor:self.topAnchor],
            [outerBg.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            // 内小框：在外框内留白（左右 30 / 上下 16）
            [cardBg.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:32],
            [cardBg.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-32],
            [cardBg.topAnchor constraintEqualToAnchor:self.topAnchor constant:16],
            [cardBg.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16],
            // 文字：在内小框里再留白（左右 46 / 上下 30）
            [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:48],
            [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-48],
            [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:45],
            [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-45],
        ]];

        // Personal build wordmark. Text scales more cleanly than modifying the
        // upstream logo asset and remains readable over every glass background.
        UILabel *wordmark = [[UILabel alloc] init];
        wordmark.translatesAutoresizingMaskIntoConstraints = NO;
        NSString *wordmarkText = @"Dopamine RH";
        UIFont *baseFont = [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold];
        UIFontDescriptor *roundedDescriptor = [baseFont.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
        UIFont *wordmarkFont = roundedDescriptor ? [UIFont fontWithDescriptor:roundedDescriptor size:30] : baseFont;
        wordmark.attributedText = [[NSAttributedString alloc] initWithString:wordmarkText attributes:@{
            NSFontAttributeName: wordmarkFont,
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.86 green:0.96 blue:1.0 alpha:1.0],
            NSKernAttributeName: @0.15,
        }];
        wordmark.textAlignment = NSTextAlignmentCenter;
        wordmark.adjustsFontSizeToFitWidth = YES;
        wordmark.minimumScaleFactor = 0.82;
        wordmark.numberOfLines = 1;
        wordmark.layer.shadowColor = [UIColor colorWithRed:0.20 green:0.65 blue:1.0 alpha:1.0].CGColor;
        wordmark.layer.shadowOffset = CGSizeZero;
        wordmark.layer.shadowRadius = 8;
        wordmark.layer.shadowOpacity = 0.30;
        [stackView addArrangedSubview:wordmark];

        [NSLayoutConstraint activateConstraints:@[
            [wordmark.heightAnchor constraintEqualToConstant:38],
            [wordmark.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor],
        ]];

        //3 - Add our subtitles to our stack
        [subtitles enumerateObjectsUsingBlock:^(NSAttributedString *formatedText, NSUInteger idx, BOOL *stop) {
            UILabel *label = [[UILabel alloc] init];
            label.attributedText = formatedText;
            label.textAlignment = NSTextAlignmentCenter;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            [stackView addArrangedSubview:label];
        }];

        self.uptimeLabel = [[UILabel alloc] init];
        self.uptimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.uptimeLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium];
        self.uptimeLabel.textAlignment = NSTextAlignmentCenter;
        self.uptimeLabel.textColor = [UIColor colorWithRed:0.62 green:0.88 blue:1.0 alpha:0.86];
        self.uptimeLabel.text = @"";
        self.uptimeLabel.hidden = YES;
        [stackView addArrangedSubview:self.uptimeLabel];

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
