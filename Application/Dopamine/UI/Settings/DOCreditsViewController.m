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

@end

@implementation DOCreditsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    // Draw an explicit light box (faint fill + faint hairline border) on
    // every grouped section (Developers / UI and Design / Credits) instead of
    // relying on the stock grouped background — which either renders too
    // heavy or disappears entirely depending on iOS version.
    UIView *box = [[UIView alloc] init];
    box.userInteractionEnabled = NO;
    box.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    box.layer.cornerRadius = 12;
    box.layer.cornerCurve = kCACornerCurveContinuous;
    box.layer.borderWidth = 1;
    box.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.12].CGColor;
    cell.backgroundView = box;
    cell.backgroundColor = [UIColor clearColor];
}

- (void)openSourceCode
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/roothide/Dopamine2-roothide"] options:@{} completionHandler:nil];
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
