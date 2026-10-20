#import "SZSettingsViewController.h"
#import "SZSettings.h"
#import "SZTheme.h"
#import "SZCommon.h"
#import "SZModern.h"

@interface SZSettingsViewController () {
    UITableView *_tableView;
}
@end

@implementation SZSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = L(@"SETTINGS");
    self.view.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:237.0/255.0 alpha:1.0];

    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:L(@"DONE")
                                                                 style:UIBarButtonItemStyleDone
                                                                target:self
                                                                action:@selector(doneTapped)];
    self.navigationItem.leftBarButtonItem = doneItem;

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.backgroundView = nil;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}

- (void)doneTapped
{
    [[SZSettings sharedSettings] save];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 3; // Auto-listen, Vibrate, Duration
    if (section == 1) return 4; // Muzika, Spot6, Tubie, Safari
    if (section == 2) return 2; // Version, Credits
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) return L(@"GENERAL");
    if (section == 1) return L(@"SETTINGS_PREFERRED_PLAYER");
    if (section == 2) return L(@"ABOUT");
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.textLabel.text = L(@"SETTINGS_AUTO_LISTEN");
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = [SZSettings sharedSettings].autoListenOnLaunch;
            [sw addTarget:self action:@selector(autoListenChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else if (indexPath.row == 1) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.textLabel.text = L(@"SETTINGS_VIBRATE");
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = [SZSettings sharedSettings].vibrateOnMatch;
            [sw addTarget:self action:@selector(vibrateChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else if (indexPath.row == 2) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            cell.textLabel.text = L(@"SETTINGS_DURATION");
            NSTimeInterval d = [SZSettings sharedSettings].listenDuration;
            if (d <= 4.5) cell.detailTextLabel.text = L(@"SETTINGS_DURATION_SHORT");
            else if (d <= 7.0) cell.detailTextLabel.text = L(@"SETTINGS_DURATION_NORMAL");
            else cell.detailTextLabel.text = L(@"SETTINGS_DURATION_LONG");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        NSArray *titles = @[L(@"PLAYER_MUZIKA"), L(@"PLAYER_SPOT6"), L(@"PLAYER_TUBIE"), L(@"PLAYER_WEB")];
        cell.textLabel.text = [titles objectAtIndex:indexPath.row];
        if ([SZSettings sharedSettings].preferredPlayer == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            cell.textLabel.text = L(@"VERSION");
            cell.detailTextLabel.text = @"1.0.0 (iOS 6 + 14)";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            cell.textLabel.text = @"Shazamer by samcejko";
            cell.detailTextLabel.text = L(@"CREDITS");
            cell.detailTextLabel.numberOfLines = 2;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }
    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0 && indexPath.row == 2) {
        // Toggle duration 4 -> 6 -> 9 -> 4
        NSTimeInterval cur = [SZSettings sharedSettings].listenDuration;
        if (cur <= 4.5) [SZSettings sharedSettings].listenDuration = 6.0;
        else if (cur <= 7.0) [SZSettings sharedSettings].listenDuration = 9.0;
        else [SZSettings sharedSettings].listenDuration = 4.5;
        [[SZSettings sharedSettings] save];
        [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (indexPath.section == 1) {
        [SZSettings sharedSettings].preferredPlayer = (SZPreferredPlayer)indexPath.row;
        [[SZSettings sharedSettings] save];
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)autoListenChanged:(UISwitch *)sw
{
    [SZSettings sharedSettings].autoListenOnLaunch = sw.on;
    [[SZSettings sharedSettings] save];
}

- (void)vibrateChanged:(UISwitch *)sw
{
    [SZSettings sharedSettings].vibrateOnMatch = sw.on;
    [[SZSettings sharedSettings] save];
}

@end
