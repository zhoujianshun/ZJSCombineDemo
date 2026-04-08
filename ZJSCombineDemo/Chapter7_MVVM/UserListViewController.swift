import Combine
import UIKit

class UserListViewController: UITableViewController {
    private let viewModel = UserListViewModel()
    private var cancellables = Set<AnyCancellable>()
//    private var users: [UserItem] = []

    var users: [UserItem] {
        return viewModel.users
    }

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        let refreshControl = UIRefreshControl()
        refreshControl.addAction(UIAction { [weak self] _ in
            self?.viewModel.fetchUsers()
        }, for: .valueChanged)
        self.refreshControl = refreshControl

        setupLoadingView()
        setupBindings()
        viewModel.fetchUsers()
    }

    private func setupLoadingView() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Combine Bindings

    private func setupBindings() {
        // 用户列表更新 → 刷新表格
        viewModel.$users
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
//                self?.users = users
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
            }
            .store(in: &cancellables)

        // 加载状态 → 指示器
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        // 错误信息 → 弹窗
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.refreshControl?.endRefreshing()
                let alert = UIAlertController(title: "加载失败", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "重试", style: .default) { _ in
                    self?.viewModel.fetchUsers()
                })
                alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let user = users[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = user.name
        config.secondaryText = "\(user.email) · \(user.phone)"
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.font = .systemFont(ofSize: 12)
        cell.contentConfiguration = config
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        users.isEmpty ? nil : "共 \(users.count) 位用户 (来自 JSONPlaceholder)"
    }
}
