#import "SZHistoryViewController.h"
#import "SZHistoryStore.h"
#import "SZTrackViewController.h"
#import "SZShazamClient.h"
#import "SZTheme.h"
#import "SZUtils.h"
#import "SZCommon.h"
#import "SZModern.h"
#import <QuartzCore/QuartzCore.h>

@interface SZHistoryViewController () {
    UITableView *_tableView;
    UILabel *_emptyLabel;
}
@end

@implementation SZHistoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = L(@"MY_TAGS");
    self.view.backgroundColor = [SZTheme backgroundDark];

    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:L(@"DONE")
                                                                 style:UIBarButtonItemStyleDone
                                                                target:self
                                                                action:@selector(doneTapped)];
    self.navigationItem.leftBarButtonItem = doneItem;

    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:L(@"CLEAR")
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(clearTapped)];
    self.navigationItem.rightBarButtonItem = clearItem;

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [SZTheme backgroundDark];
    _tableView.separatorColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    _tableView.rowHeight = 64.0;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];

    _emptyLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    _emptyLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyLabel.backgroundColor = [UIColor clearColor];
    _emptyLabel.textColor = [SZTheme textSecondary];
    _emptyLabel.font = [UIFont systemFontOfSize:16.0];
    _emptyLabel.textAlignment = UITextAlignmentCenter;
    _emptyLabel.numberOfLines = 3;
    _emptyLabel.text = L(@"HISTORY_EMPTY");
    [self.view addSubview:_emptyLabel];

    [self updateEmptyState];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(historyChanged)
                                                 name:SZHistoryDidChangeNotification
                                               object:nil];
}

- (void)updateEmptyState
{
    BOOL hasTracks = [SZHistoryStore sharedStore].tracks.count > 0;
    _emptyLabel.hidden = hasTracks;
    _tableView.hidden = !hasTracks;
    self.navigationItem.rightBarButtonItem.enabled = hasTracks;
}

- (void)historyChanged
{
    [_tableView reloadData];
    [self updateEmptyState];
}

- (void)doneTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clearTapped
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:L(@"CLEAR_HISTORY_CONFIRM")
                                                       delegate:self
                                              cancelButtonTitle:L(@"CANCEL")
                                         destructiveButtonTitle:L(@"CLEAR_HISTORY")
                                              otherButtonTitles:nil];
    if (SZIsPad() && [sheet respondsToSelector:@selector(showFromBarButtonItem:animated:)]) {
        [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    } else {
        [sheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [[SZHistoryStore sharedStore] clearHistory];
    }
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [SZHistoryStore sharedStore].tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId = @"SZHistoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [SZTheme textPrimary];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        cell.detailTextLabel.textColor = [SZTheme textSecondary];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        cell.imageView.layer.cornerRadius = 6.0;
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
        cell.imageView.layer.borderWidth = 0.5;
    }

    SZTrack *t = [[SZHistoryStore sharedStore].tracks objectAtIndex:indexPath.row];

    if ([t isPendingOffline]) {
        cell.textLabel.text = L(@"OFFLINE_PENDING");
        cell.detailTextLabel.text = [SZUtils formattedDate:t.tagDate];
        cell.imageView.image = [UIImage imageNamed:@"Icon-Small-50@2x.png"];
    } else {
        cell.textLabel.text = t.title ?: @"";
        NSString *sub = t.artist ?: @"";
        if (t.tagDate) {
            sub = [NSString stringWithFormat:@"%@ • %@", sub, [SZUtils formattedDate:t.tagDate]];
        }
        cell.detailTextLabel.text = sub;

        if (t.coverArtImage) {
            cell.imageView.image = t.coverArtImage;
        } else {
            cell.imageView.image = [UIImage imageNamed:@"Icon-Small-50@2x.png"];
            if (t.coverArtUrl.length) {
                __weak typeof(self) weakSelf = self;
                [[SZShazamClient sharedClient] fetchCoverImageForTrack:t completion:^(UIImage *img) {
                    if (img) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            SZHistoryViewController *strongSelf = weakSelf;
                            if (strongSelf) {
                                [strongSelf->_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                            }
                        });
                    }
                }];
            }
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SZTrack *t = [[SZHistoryStore sharedStore].tracks objectAtIndex:indexPath.row];

    if ([t isPendingOffline]) {
        /* Retry recognition */
        [self retryPendingTrack:t];
    } else {
        SZTrackViewController *vc = [[SZTrackViewController alloc] initWithTrack:t];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)retryPendingTrack:(SZTrack *)pending
{
    UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:act];
    [act startAnimating];

    [[SZShazamClient sharedClient]
        recognizeWithSignatureURI:pending.pendingSignatureURI
        sampleMs:6000
        completion:^(SZTrack *recognized, NSError *error) {
            [act stopAnimating];
            UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:L(@"CLEAR")
                                                                          style:UIBarButtonItemStyleBordered
                                                                         target:self
                                                                         action:@selector(clearTapped)];
            self.navigationItem.rightBarButtonItem = clearItem;

            if (recognized) {
                [[SZHistoryStore sharedStore] replacePendingTrack:pending withTrack:recognized];
                SZTrackViewController *vc = [[SZTrackViewController alloc] initWithTrack:recognized];
                [self.navigationController pushViewController:vc animated:YES];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:L(@"APP_NAME")
                                                               message:error.localizedDescription ?: L(@"NO_MATCH")
                                                              delegate:nil
                                                     cancelButtonTitle:L(@"DONE")
                                                     otherButtonTitles:nil];
                [alert show];
            }
        }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[SZHistoryStore sharedStore] removeTrackAtIndex:indexPath.row];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
