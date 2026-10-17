___FILEHEADER___

import Core
import DesignSystem
import UIKit

/// Storyboard-backed screen. Only renders state and forwards user actions.
final class ___VARIABLE_sceneName___ViewController: UIViewController, StoryboardInstantiable {
    static var bundle: Bundle { .module }

    // Outlets are weak: the view hierarchy already owns the views.
    @IBOutlet private weak var tableView: UITableView!

    /// Injected by the Builder right after `instantiate()`. Optional, not `!`:
    /// a missing injection shows an empty screen instead of crashing.
    var presenter: (any ___VARIABLE_sceneName___Presenting)?

    private var items: [___VARIABLE_sceneName___Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // navigationItem.title (not `title`): `title` would also rename the tab bar item.
        navigationItem.title = "___VARIABLE_sceneName___"
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

extension ___VARIABLE_sceneName___ViewController: ___VARIABLE_sceneName___ViewInput {
    func render(_ state: Loadable<[___VARIABLE_sceneName___Item]>) {
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
            contentUnavailableConfiguration = items.isEmpty ? Self.emptyConfiguration : nil
        case let .failed(message):
            tableView.refreshControl?.endRefreshing()
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.image = UIImage(systemName: "exclamationmark.triangle")
            configuration.text = "Something went wrong"
            configuration.secondaryText = message
            contentUnavailableConfiguration = configuration
        }
    }

    private static var emptyConfiguration: UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "tray")
        configuration.text = "Nothing here yet"
        return configuration
    }
}

// MARK: - Table

extension ___VARIABLE_sceneName___ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = items[indexPath.row].title
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter?.didSelectItem(at: indexPath.row)
    }
}
