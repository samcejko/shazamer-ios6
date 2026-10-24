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
    UISearchBar *_searchBar;
    UISegmentedControl *_filter;
    NSArray *_visibleTracks;
    BOOL _retrying;
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
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 88)];
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _filter = [[UISegmentedControl alloc] initWithItems:@[L(@"ALL_TRACKS"), L(@"FAVORITES")]];
    _filter.frame = CGRectMake(12, 6, header.bounds.size.width - 24, 30);
    _filter.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _filter.selectedSegmentIndex = 0;
    [_filter addTarget:self action:@selector(refreshTracks) forControlEvents:UIControlEventValueChanged];
    [header addSubview:_filter];
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 40, header.bounds.size.width, 44)];
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _searchBar.placeholder = L(@"SEARCH_HISTORY");
    _searchBar.delegate = self;
    [header addSubview:_searchBar];
    _tableView.tableHeaderView = header;


    _emptyLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    _emptyLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyLabel.backgroundColor = [UIColor clearColor];
    _emptyLabel.textColor = [SZTheme textSecondary];
    _emptyLabel.font = [UIFont systemFontOfSize:16.0];
    _emptyLabel.textAlignment = UITextAlignmentCenter;
    _emptyLabel.numberOfLines = 3;
    _emptyLabel.text = L(@"HISTORY_EMPTY");
    _emptyLabel.userInteractionEnabled = NO;
    [self.view addSubview:_emptyLabel];

    [self refreshTracks];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(historyChanged)
                                                 name:SZHistoryDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardChanged:(NSNotification *)notification
{
    BOOL hiding = [notification.name isEqualToString:UIKeyboardWillHideNotification];
    if (!hiding && !self.view.window) return;
    CGRect keyboard = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    CGRect overlap = CGRectIntersection(self.view.bounds, keyboard);
    UIEdgeInsets insets = _tableView.contentInset;
    insets.bottom = hiding || CGRectIsNull(overlap) ? 0 : overlap.size.height;
    _tableView.contentInset = insets;
    _tableView.scrollIndicatorInsets = insets;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGRect b = self.view.bounds;
    UIEdgeInsets insets = SZSafeAreaInsets(self.view);
    CGFloat top = insets.top + 100;
    _emptyLabel.frame = CGRectMake(20, top, b.size.width - 40, MAX(0, b.size.height - top - insets.bottom));
}

- (void)refreshTracks
{
    NSString *query = [_searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *matches = [NSMutableArray array];
    for (SZTrack *track in [SZHistoryStore sharedStore].tracks) {
        if (_filter.selectedSegmentIndex == 1 && !track.favorite) continue;
        NSString *text = [NSString stringWithFormat:@"%@ %@ %@", track.title ?: @"", track.artist ?: @"", track.album ?: @""];
        if (query.length && [text rangeOfString:query options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location == NSNotFound) continue;
        [matches addObject:track];
    }
    _visibleTracks = [matches copy];
    [_tableView reloadData];
    _emptyLabel.hidden = _visibleTracks.count > 0;
    _emptyLabel.text = query.length ? L(@"SEARCH_EMPTY") : (_filter.selectedSegmentIndex == 1 ? L(@"FAVORITES_EMPTY") : L(@"HISTORY_EMPTY"));
    self.navigationItem.rightBarButtonItem.enabled = !_retrying && [SZHistoryStore sharedStore].tracks.count > 0;
}

- (void)historyChanged { [self refreshTracks]; }
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { [self refreshTracks]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar { [searchBar resignFirstResponder]; }
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView { [_searchBar resignFirstResponder]; }

- (void)doneTapped
{
    if (_retrying) {
        _retrying = NO;
        [[SZShazamClient sharedClient] cancel];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clearTapped
{
    UIActionSheet *sheet = [[RetroActionSheet alloc] initWithTitle:L(@"CLEAR_HISTORY_CONFIRM")
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
    return _visibleTracks.count;
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

    SZTrack *t = [_visibleTracks objectAtIndex:indexPath.row];

    if ([t isPendingOffline]) {
        cell.textLabel.text = L(@"OFFLINE_PENDING");
        cell.detailTextLabel.text = [SZUtils formattedDate:t.tagDate];
        cell.imageView.image = [UIImage imageNamed:@"Icon-Small-50@2x.png"];
    } else {
        cell.textLabel.text = t.favorite ? [NSString stringWithFormat:@"★ %@", t.title ?: @""] : (t.title ?: @"");
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
                                [strongSelf->_tableView reloadData];
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
    [_searchBar resignFirstResponder];
    if (_retrying || indexPath.row >= _visibleTracks.count) return;
    SZTrack *t = [_visibleTracks objectAtIndex:indexPath.row];

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
    if (_retrying) return;
    _retrying = YES;
    UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:act];
    [act startAnimating];

    [[SZShazamClient sharedClient]
        recognizeWithSignatureURI:pending.pendingSignatureURI
        sampleMs:pending.pendingSampleMs ?: 6000
        completion:^(SZTrack *recognized, NSError *error) {
            _retrying = NO;
            [act stopAnimating];
            UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:L(@"CLEAR")
                                                                          style:UIBarButtonItemStyleBordered
                                                                         target:self
                                                                         action:@selector(clearTapped)];
            self.navigationItem.rightBarButtonItem = clearItem;

            [self refreshTracks];
            if (recognized && [[SZHistoryStore sharedStore].tracks containsObject:pending]) {
                [[SZHistoryStore sharedStore] replacePendingTrack:pending withTrack:recognized];
                SZTrackViewController *vc = [[SZTrackViewController alloc] initWithTrack:recognized];
                [self.navigationController pushViewController:vc animated:YES];
            } else {
                UIAlertView *alert = [[RetroAlertView alloc] initWithTitle:L(@"APP_NAME")
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
    return !_retrying;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.row < _visibleTracks.count) [[SZHistoryStore sharedStore] removeTrack:[_visibleTracks objectAtIndex:indexPath.row]];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
