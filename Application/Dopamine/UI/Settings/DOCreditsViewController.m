//
//  DOCreditsViewController.m
//  Dopamine
//
//  Created by tomt000 on 08/01/2024.
//

#import "DOCreditsViewController.h"
#import "DOLicenseViewController.h"
#import "DOUIManager.h"
#import "DOEnvironmentManager.h"
#import <Preferences/PSSpecifier.h>

@interface DOCreditsViewController ()

@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@property (nonatomic, strong) UIVisualEffectView *glassView;

@end

@implementation DOCreditsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.backgroundGradient = [CAGradientLayer layer];
    self.backgroundGradient.colors = @[
        (id)[UIColor colorWithRed:0.025 green:0.075 blue:0.16 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.055 green:0.38 blue:0.48 alpha:0.96].CGColor,
        (id)[UIColor colorWithRed:0.12 green:0.10 blue:0.30 alpha:1.0].CGColor,
    ];
    self.backgroundGradient.locations = @[@0.0, @0.48, @1.0];
    self.backgroundGradient.startPoint = CGPointMake(0.0, 0.0);
    self.backgroundGradient.endPoint = CGPointMake(1.0, 1.0);
    [self.view.layer insertSublayer:self.backgroundGradient atIndex:0];

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    self.glassView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.glassView.translatesAutoresizingMaskIntoConstraints = NO;
    self.glassView.userInteractionEnabled = NO;
    self.glassView.backgroundColor = [UIColor colorWithRed:0.20 green:0.68 blue:0.92 alpha:0.05];
    [self.view insertSubview:self.glassView atIndex:0];
    [self.view.layer insertSublayer:self.backgroundGradient below:self.glassView.layer];
    [NSLayoutConstraint activateConstraints:@[
        [self.glassView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.glassView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.glassView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.glassView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.view.backgroundColor = [UIColor clearColor];
    _table.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.backgroundGradient.frame = self.view.bounds;
}

- (id)specifiers
{
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Credits" target:self];

        PSSpecifier *headerSpecifier = _specifiers[0];
        [headerSpecifier setProperty:@"Dopamine 3.0.7 RootHide" forKey:@"title"];
    }
    return _specifiers;
}

- (void)openSourceCode
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/opa334/Dopamine"] options:@{} completionHandler:nil];
}

- (void)openDiscord
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://discord.gg/jb"] options:@{} completionHandler:nil];
}

- (void)openLicense
{
    [self.navigationController pushViewController:[[DOLicenseViewController alloc] init] animated:YES];
}

@end
