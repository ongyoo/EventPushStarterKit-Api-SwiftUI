//
//  NotificationViewController.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import UIKit

/// Storyboard-backed screen. Only renders state and forwards user actions.
final class NotificationViewController: UIViewController, StoryboardInstantiable {
    static var bundle: Bundle { .module }

    // Outlets are weak: the view hierarchy already owns the views.
    @IBOutlet private weak var tableView: UITableView!

    /// Injected by the Builder right after `instantiate()`. Optional, not `!`:
    /// a missing injection shows an empty screen instead of crashing.
    var presenter: (any NotificationPresenting)?

    private var items: [NotificationItem] = []
    private var hasAnimatedFirstLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // navigationItem.title (not `title`): `title` would also rename the tab bar item.
        navigationItem.title = L10n.Inbox.title
        configureTableView()
        presenter?.viewDidLoad()
    }

    private func configureTableView() {
        tableView.register(UITableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        let refresh = UIRefreshControl()
        // UIAction closures capture weakly to avoid VC <-> control cycles.
        refresh.addAction(UIAction { [weak self] _ in self?.presenter?.didPullToRefresh() }, for: .valueChanged)
        tableView.refreshControl = refresh
    }

    #if DEBUG
    deinit { print("♻️ deinit \(type(of: self))") }
    #endif
}

// MARK: - ViewInput

extension NotificationViewController: NotificationViewInput {
    func render(_ state: Loadable<[NotificationItem]>) {
        switch state {
        case .idle:
            contentUnavailableConfiguration = nil
        case .loading:
            if tableView.refreshControl?.isRefreshing != true {
                contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
            }
        case let .loaded(items):
            tableView.refreshControl?.endRefreshing()
            self.items = items
            tableView.reloadData()
            if !hasAnimatedFirstLoad, !items.isEmpty {
                hasAnimatedFirstLoad = true
                tableView.layoutIfNeeded()
                tableView.animateVisibleCells()
            }
            contentUnavailableConfiguration = items.isEmpty ? Self.emptyConfiguration : nil
        case let .failed(message):
            tableView.refreshControl?.endRefreshing()
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.image = UIImage(systemName: "exclamationmark.triangle")
            configuration.text = L10n.tr("common.error.title")
            configuration.secondaryText = message
            contentUnavailableConfiguration = configuration
        }
    }

    private static var emptyConfiguration: UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "tray")
        configuration.text = L10n.Inbox.empty
        return configuration
    }
}

// MARK: - Table

extension NotificationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        var content = UIListContentConfiguration.subtitleCell()
        content.image = UIImage(systemName: item.kind.iconName)
        content.imageProperties.tintColor = UIColor.brandPrimary
        content.text = item.title
        content.secondaryText = "\(item.body)\n\(item.date.relativeText)"
        content.secondaryTextProperties.color = UIColor.textSecondary
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        cell.accessoryType = item.eventID == nil ? .none : .disclosureIndicator
        cell.selectionStyle = item.eventID == nil ? .none : .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter?.didSelectItem(at: indexPath.row)
    }
}
