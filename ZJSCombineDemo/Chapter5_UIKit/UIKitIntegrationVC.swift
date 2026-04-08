import UIKit
import Combine

class UIKitIntegrationVC: BaseLogViewController {

    @Published private var searchText = ""
    private let textField = UITextField()
    private let resultLabel = UILabel()
    private var timerCancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomUI()
        setupPublishedBinding()
    }

    // MARK: - UI Setup

    private func setupCustomUI() {
        addSectionHeader("— @Published + TextField 绑定 —")

        textField.placeholder = "输入搜索内容，观察 debounce 效果..."
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        controlStackView.addArrangedSubview(textField)

        resultLabel.text = "搜索结果将显示在这里"
        resultLabel.textColor = .secondaryLabel
        resultLabel.font = .systemFont(ofSize: 14)
        controlStackView.addArrangedSubview(resultLabel)

        addSectionHeader("— 其他集成方式 —")
        addButton(title: "KVO 监听 (UIScrollView)")   { [weak self] in self?.demoKVO() }
        addButton(title: "NotificationCenter 监听")    { [weak self] in self?.demoNotificationCenter() }
        addButton(title: "Timer.publish 启动")         { [weak self] in self?.demoTimer() }
        addButton(title: "Timer 停止")                 { [weak self] in self?.stopTimer() }
    }

    // MARK: - @Published: TextField → 属性 → UI

    private func setupPublishedBinding() {
        // UITextField 文字变化 → @Published 属性
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: textField)
            .compactMap { ($0.object as? UITextField)?.text }
            .assign(to: &$searchText)

        // @Published 属性 → debounce → 更新 UI
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.resultLabel.text = text.isEmpty
                    ? "搜索结果将显示在这里"
                    : "🔍 搜索: \"\(text)\""
                self?.log("@Published → \"\(text)\"")
            }
            .store(in: &cancellables)
    }

    // MARK: - KVO with Combine

    private func demoKVO() {
        log("--- KVO: 监听 UIScrollView.contentOffset ---")

        let scrollView = UIScrollView()

        scrollView.publisher(for: \.contentOffset)
            .sink { [weak self] offset in
                self?.log("contentOffset → \(offset)")
            }
            .store(in: &cancellables)

        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        scrollView.contentOffset = CGPoint(x: 0, y: 200)
        scrollView.contentOffset = CGPoint(x: 50, y: 300)
    }

    // MARK: - NotificationCenter with Combine

    private func demoNotificationCenter() {
        log("--- NotificationCenter with Combine ---")

        // 监听自定义通知
        let customName = Notification.Name("CombineDemoNotification")

        NotificationCenter.default.publisher(for: customName)
            .sink { [weak self] notification in
                let info = notification.userInfo ?? [:]
                self?.log("收到自定义通知: \(info)")
            }
            .store(in: &cancellables)

        // 监听 App 进入前台
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.log("App 即将进入前台")
            }
            .store(in: &cancellables)

        // 发送自定义通知
        NotificationCenter.default.post(
            name: customName, object: nil,
            userInfo: ["message": "Hello from Combine!"]
        )

        log("已订阅前台通知，切到后台再回来可触发")
    }

    // MARK: - Timer.publish

    private func demoTimer() {
        log("--- Timer.publish (每秒触发) ---")
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                self?.log("⏱ Timer: \(formatter.string(from: date))")
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        log("Timer 已停止")
    }
}
