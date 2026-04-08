import UIKit

private struct DemoItem {
    let title: String
    let subtitle: String
    let makeViewController: () -> UIViewController
}

private struct ChapterSection {
    let title: String
    let items: [DemoItem]
}

class ChapterListViewController: UITableViewController {

    private var sections: [ChapterSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Combine 学习"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        buildSections()
    }

    private func buildSections() {
        sections = [
            ChapterSection(title: "第1章 · 基础概念", items: [
                DemoItem(title: "Publisher & Subscriber",
                         subtitle: "Just, Future, Empty, Fail, Deferred, sink, assign",
                         makeViewController: { BasicsViewController() }),
            ]),
            ChapterSection(title: "第2章 · 操作符", items: [
                DemoItem(title: "转换操作符",
                         subtitle: "map, flatMap, compactMap, scan, reduce",
                         makeViewController: { TransformOperatorsVC() }),
                DemoItem(title: "过滤操作符",
                         subtitle: "filter, removeDuplicates, debounce, throttle, first, last",
                         makeViewController: { FilterOperatorsVC() }),
                DemoItem(title: "组合操作符",
                         subtitle: "merge, combineLatest, zip, switchToLatest",
                         makeViewController: { CombineOperatorsVC() }),
                DemoItem(title: "错误处理操作符",
                         subtitle: "catch, retry, replaceError, mapError",
                         makeViewController: { ErrorHandlingOperatorsVC() }),
            ]),
            ChapterSection(title: "第3章 · Subject", items: [
                DemoItem(title: "Subject",
                         subtitle: "PassthroughSubject, CurrentValueSubject",
                         makeViewController: { SubjectsViewController() }),
            ]),
            ChapterSection(title: "第4章 · Scheduler", items: [
                DemoItem(title: "Scheduler",
                         subtitle: "receive(on:), subscribe(on:), 线程切换",
                         makeViewController: { SchedulersViewController() }),
            ]),
            ChapterSection(title: "第5章 · Combine 与 UIKit", items: [
                DemoItem(title: "UIKit 集成",
                         subtitle: "@Published, KVO, NotificationCenter, Timer",
                         makeViewController: { UIKitIntegrationVC() }),
            ]),
            ChapterSection(title: "第6章 · 网络请求", items: [
                DemoItem(title: "网络请求",
                         subtitle: "URLSession, JSON 解析, 错误处理, 链式请求",
                         makeViewController: { NetworkingViewController() }),
            ]),
            ChapterSection(title: "第7章 · MVVM 架构", items: [
                DemoItem(title: "登录表单验证",
                         subtitle: "多字段联合校验 + Combine 绑定",
                         makeViewController: { LoginViewController() }),
                DemoItem(title: "用户列表",
                         subtitle: "列表页 MVVM 实战",
                         makeViewController: { UserListViewController() }),
            ]),
            ChapterSection(title: "第8章 · 高级主题", items: [
                DemoItem(title: "高级主题",
                         subtitle: "自定义 Publisher, 背压, Combine ↔ async/await",
                         makeViewController: { AdvancedTopicsVC() }),
            ]),
        ]
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.secondaryText = item.subtitle
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.font = .systemFont(ofSize: 12)
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        let vc = item.makeViewController()
        vc.title = item.title
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}
