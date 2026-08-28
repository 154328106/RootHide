//
//  DORootHideHealthViewController.m
//  Dopamine
//

#import "DORootHideHealthViewController.h"
#import "DORootHideHealthManager.h"
#import "DOButtonCell.h"
#import "DOHeaderCell.h"
#import "DOUIManager.h"

@interface DORootHideHealthViewController ()
@property (nonatomic, copy) NSArray<DORootHideHealthItem *> *healthItems;
@property (nonatomic) BOOL scanInProgress;
@property (nonatomic) BOOL repairInProgress;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@end

@implementation DORootHideHealthViewController

- (void)viewDidLoad
{
    self.scanInProgress = YES;
    [super viewDidLoad];
    self.title = DOLocalizedString(@"Health_Title");
    self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self
                                                                      action:@selector(refreshPressed)];
    self.refreshButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = self.refreshButton;
    [self performHealthScan];
}

- (NSArray *)specifiers
{
    if (_specifiers != nil) return _specifiers;

    NSMutableArray *specifiers = [NSMutableArray new];
    PSSpecifier *header = [PSSpecifier emptyGroupSpecifier];
    [header setProperty:@"DOHeaderCell" forKey:@"headerCellClass"];
    [header setProperty:DOLocalizedString(@"Health_Title") forKey:@"title"];
    [specifiers addObject:header];

    PSSpecifier *intro = [PSSpecifier groupSpecifierWithHeader:nil footer:DOLocalizedString(@"Health_Intro")];
    [specifiers addObject:intro];

    if (self.scanInProgress || self.healthItems.count == 0) {
        PSSpecifier *checking = [PSSpecifier preferenceSpecifierNamed:DOLocalizedString(@"Health_Status_Checking")
                                                               target:self
                                                                  set:nil
                                                                  get:nil
                                                               detail:nil
                                                                 cell:PSStaticTextCell
                                                                 edit:nil];
        [specifiers addObject:checking];
    }
    else {
        NSNumber *buttonHeight = @(44);
        for (DORootHideHealthItem *item in self.healthItems) {
            PSSpecifier *group = [PSSpecifier groupSpecifierWithHeader:item.title footer:item.detail];
            [specifiers addObject:group];

            PSSpecifier *status = [PSSpecifier preferenceSpecifierNamed:item.localizedStateTitle
                                                                  target:self
                                                                     set:nil
                                                                     get:nil
                                                                  detail:nil
                                                                    cell:PSStaticTextCell
                                                                    edit:nil];
            [specifiers addObject:status];

            if (item.canRepair) {
                PSSpecifier *repair = [PSSpecifier preferenceSpecifierNamed:@""
                                                                  target:self
                                                                     set:nil
                                                                     get:nil
                                                                  detail:nil
                                                                    cell:PSStaticTextCell
                                                                    edit:nil];
                [repair setProperty:[DOButtonCell class] forKey:@"cellClass"];
                [repair setProperty:buttonHeight forKey:@"height"];
                [repair setProperty:@"wrench.and.screwdriver" forKey:@"image"];
                [repair setProperty:@"Health_Repair" forKey:@"title"];
                [repair setProperty:@"repairPressed:" forKey:@"action"];
                [repair setProperty:item.identifier forKey:@"key"];
                [specifiers addObject:repair];
            }
        }
    }

    _specifiers = specifiers;
    return _specifiers;
}

- (void)refreshPressed
{
    if (self.scanInProgress || self.repairInProgress) return;
    self.scanInProgress = YES;
    self.refreshButton.enabled = NO;
    _specifiers = nil;
    [self reloadSpecifiers];
    [self performHealthScan];
}

- (void)performHealthScan
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray<DORootHideHealthItem *> *items = [[DORootHideHealthManager sharedManager] scanHealth];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.healthItems = items;
            self.scanInProgress = NO;
            self.refreshButton.enabled = !self.repairInProgress;
            self->_specifiers = nil;
            [self reloadSpecifiers];
        });
    });
}

- (DORootHideHealthItem *)itemWithIdentifier:(NSString *)identifier
{
    for (DORootHideHealthItem *item in self.healthItems) {
        if ([item.identifier isEqualToString:identifier]) return item;
    }
    return nil;
}

- (void)repairPressed:(PSSpecifier *)specifier
{
    if (self.scanInProgress || self.repairInProgress) return;
    NSString *identifier = [specifier propertyForKey:@"key"];
    DORootHideHealthItem *item = [self itemWithIdentifier:identifier];
    if (!item.canRepair) return;

    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:DOLocalizedString(@"Health_Repair_Confirm_Title"), item.title]
                                                                           message:DOLocalizedString(@"Health_Repair_Confirm_Detail")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
    [confirmation addAction:[UIAlertAction actionWithTitle:DOLocalizedString(@"Button_Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [confirmation addAction:[UIAlertAction actionWithTitle:DOLocalizedString(@"Health_Repair") style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self beginRepairForIdentifier:identifier title:item.title];
    }]];
    [self presentViewController:confirmation animated:YES completion:nil];
}

- (void)beginRepairForIdentifier:(NSString *)identifier title:(NSString *)title
{
    self.repairInProgress = YES;
    self.refreshButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = [[DORootHideHealthManager sharedManager] repairItemWithIdentifier:identifier];
        NSArray<DORootHideHealthItem *> *items = [[DORootHideHealthManager sharedManager] scanHealth];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.healthItems = items;
            self.repairInProgress = NO;
            self.refreshButton.enabled = YES;
            self->_specifiers = nil;
            [self reloadSpecifiers];

            NSString *alertTitle = error ? DOLocalizedString(@"Health_Repair_Failed") : DOLocalizedString(@"Health_Repair_Succeeded");
            NSString *message = error.localizedDescription ?: [NSString stringWithFormat:DOLocalizedString(@"Health_Repair_Succeeded_Detail"), title];
            UIAlertController *result = [UIAlertController alertControllerWithTitle:alertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
            [result addAction:[UIAlertAction actionWithTitle:DOLocalizedString(@"Button_OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:result animated:YES completion:nil];
        });
    });
}

@end
